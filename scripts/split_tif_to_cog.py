import os
import math
import numpy as np
import rasterio
from rasterio.windows import from_bounds

# --- CONFIGURACIÓ ---
CARPETA_ENTRADA = "./mde_originals"  # Canvia-ho per la teva carpeta d'entrada
CARPETA_SORTIDA = (
    "./mde_cog_1deg"  # Canvia-ho per la carpeta on vols desar els resultats
)

# Crear la carpeta de sortida si no existeix
os.makedirs(CARPETA_SORTIDA, exist_ok=True)


def generar_nom_arxiu(lat, lon):
    """Genera el nom de l'arxiu basat en la latitud i longitud (ex: N60W003_cog.tif)"""
    ns = "N" if lat >= 0 else "S"
    ew = "E" if lon >= 0 else "W"

    # Utilitzem el valor absolut per al nom del fitxer
    lat_val = abs(lat)
    lon_val = abs(lon)

    return f"{ns}{lat_val:02d}{ew}{lon_val:03d}_cog.tif"


def processar_fitxers():
    # Buscar tots els arxius .tif a la carpeta d'entrada
    arxius = [
        f
        for f in os.listdir(CARPETA_ENTRADA)
        if f.lower().endswith(".tif") and not f.endswith("_cog.tif")
    ]

    if not arxius:
        print(f"No s'ha trobat cap arxiu .tif a {CARPETA_ENTRADA}")
        return

    for arxiu in arxius:
        ruta_completa = os.path.join(CARPETA_ENTRADA, arxiu)
        print(f"\nProcessant l'arxiu: {arxiu}...")

        with rasterio.open(ruta_completa) as src:
            # Comprovació del sistema de coordenades (Ha de ser geogràfic, ex: EPSG:4326)
            if not src.crs or not src.crs.is_geographic:
                print(
                    f"Alerta: L'arxiu {arxiu} no utilitza coordenades geogràfiques (Lat/Lon). L'script podria no funcionar correctament."
                )

            # Obtenir els límits de l'arxiu actual
            esquerra, inferior, dreta, superior = src.bounds

            # Calcular els graus sencers per on s'ha de tallar
            lat_min = math.floor(inferior)
            lat_max = math.ceil(superior)
            lon_min = math.floor(esquerra)
            lon_max = math.ceil(dreta)

            # Iterar per cada cel·la de 1x1 grau
            for lat in range(lat_min, lat_max):
                for lon in range(lon_min, lon_max):

                    # Definir els límits del tall actual de 1x1 grau
                    t_esquerra = lon
                    t_inferior = lat
                    t_dreta = lon + 1
                    t_superior = lat + 1

                    # Crear la finestra de lectura per rasterio
                    window = from_bounds(
                        t_esquerra,
                        t_inferior,
                        t_dreta,
                        t_superior,
                        transform=src.transform,
                    )

                    # Arredonir coordenades de la finestra per evitar errors de píxels flotants
                    window = window.round_shape()

                    # Si la finestra està completament fora de l'arxiu original, es salta
                    if window.width <= 0 or window.height <= 0:
                        continue

                    # Llegir les dades de la finestra
                    dades = src.read(window=window)

                    # Si tot el tros són dades buides (NoData), es pot saltar per estalviar espai
                    if src.nodata is not None and np.all(dades == src.nodata):
                        continue

                    # Calcular la nova transformació geogràfica per a aquest tros
                    nova_transform = rasterio.windows.transform(window, src.transform)

                    # Configurar les metadades per al format COG
                    meta_sortida = src.meta.copy()
                    meta_sortida.update(
                        {
                            "driver": "GTiff",  # El driver de GDAL per a COG segueix sent GTiff
                            "height": window.height,
                            "width": window.width,
                            "transform": nova_transform,
                            # Paràmetres específics per a Cloud Optimized GeoTIFF (COG):
                            "tiled": True,
                            "blockxsize": 256,
                            "blockysize": 256,
                            "compress": "deflate",  # Compressió recomanada per a MDE/DEM
                        }
                    )

                    # Generar el nom segons la lògica demanada (es pren la cantonada Nord-Oest com a referència habitual)
                    # En el teu exemple N60W003 correspon a la cel·la que va de Lat 59 a 60 i Lon -3 a -2.
                    nom_final = generar_nom_arxiu(t_superior, t_esquerra)
                    ruta_sortida = os.path.join(CARPETA_SORTIDA, nom_final)

                    # Escriure l'arxiu tallat en format COG
                    with rasterio.open(ruta_sortida, "w", **meta_sortida) as dest:
                        dest.write(dades)

                    print(f" -> Creat: {nom_final}")


if __name__ == "__main__":
    processar_fitxers()
    print("\nProcés finalitzat amb èxit!")
