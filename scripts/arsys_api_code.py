import os
import math

# -------------------------------------------------------------------------
# 1. CONFIGURACIÓ PROJ / GDAL PER RASTERIO (WINDOWS + DOCKER LINUX)
# -------------------------------------------------------------------------

# Eliminem possibles configuracions externes incorrectes
for var in ["PROJ_LIB", "PROJ_DATA", "GDAL_DATA"]:
    os.environ.pop(var, None)

import rasterio

# Utilitza el proj_data inclòs amb rasterio
RASTERIO_PROJ = os.path.join(os.path.dirname(rasterio.__file__), "proj_data")

os.environ["PROJ_DATA"] = RASTERIO_PROJ
os.environ["PROJ_LIB"] = RASTERIO_PROJ

# Optimització per Cloud Optimized GeoTIFF
os.environ["GDAL_DISABLE_READDIR_ON_OPEN"] = "EMPTY_DIR"
os.environ["CPL_VSIL_CURL_ALLOWED_EXTENSIONS"] = ".tif"


# -------------------------------------------------------------------------
# 2. IMPORTACIÓ FASTAPI / RIO-TILER
# -------------------------------------------------------------------------

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from rio_tiler.io import COGReader
import numpy as np

app = FastAPI(
    title="Servidor de Retalls COG",
    description="API per obtenir retalls de fitxers COG locals",
    root_path="/api",
)


# -------------------------------------------------------------------------
# 3. CONFIGURACIÓ CORS
# -------------------------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET"],
    allow_headers=["*"],
    expose_headers=["x-bbox", "x-width", "x-height", "Content-Disposition"],
)


# -------------------------------------------------------------------------
# 4. CONFIGURACIÓ DE FITXERS LOCALS
# -------------------------------------------------------------------------

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

COG_FOLDER_PATH = os.path.join(BASE_DIR, "dades_cog")


def obtenir_ruta_local_cog(lat: float, lon: float) -> str:
    l_lat, l_lon = int(lat), int(lon)

    ns = "N" if l_lat >= 0 else "S"
    ew = "E" if l_lon >= 0 else "W"

    blob_name = f"{ns}{abs(l_lat):02d}" f"{ew}{abs(l_lon):03d}_cog.tif"

    ruta_completa = os.path.join(COG_FOLDER_PATH, blob_name)

    if not os.path.exists(ruta_completa):
        raise HTTPException(status_code=404, detail=f"No es troba l'arxiu {blob_name}")

    return ruta_completa


# -------------------------------------------------------------------------
# 5. GET TILE - RETALL 500x500
# -------------------------------------------------------------------------


@app.get("/getTile")
def get_tile(
    lat: float = Query(...), lon: float = Query(...), buf: float = Query(None)
):

    try:
        buffer = buf if buf is not None else 0.07

        ruta_fitxer_local = obtenir_ruta_local_cog(lat, lon)

        with COGReader(ruta_fitxer_local) as cog:

            img = cog.part(
                (lon - buffer, lat - buffer, lon + buffer, lat + buffer),
                width=500,
                height=500,
            )

            raw_data = img.data.astype(np.float32).tobytes()

            headers = {
                "Content-Disposition": f"attachment; filename={os.path.basename(ruta_fitxer_local)}.bin",
                "x-bbox": f"{lon-buffer},{lat-buffer},{lon+buffer},{lat+buffer}",
                "x-width": "500",
                "x-height": "500",
            }

            return Response(
                content=raw_data, media_type="application/octet-stream", headers=headers
            )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------------------
# 6. GET TILE GRID - CEL·LA NATIVA 0.2x0.2
# -------------------------------------------------------------------------


@app.get("/getTileGrid")
def get_tile_grid(lat: float = Query(...), lon: float = Query(...)):

    try:
        tile_lat = round(math.floor(lat / 0.2) * 0.2, 2)
        tile_lon = round(math.floor(lon / 0.2) * 0.2, 2)

        bbox = (tile_lon, tile_lat, round(tile_lon + 0.2, 2), round(tile_lat + 0.2, 2))

        ruta_fitxer_local = obtenir_ruta_local_cog(lat, lon)

        with COGReader(ruta_fitxer_local) as cog:

            img = cog.part(bbox)

            raw_data = img.data.astype(np.float32).tobytes()

            headers = {
                "Content-Disposition": f"attachment; filename=tile_{tile_lat}_{tile_lon}.bin",
                "x-bbox": f"{bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]}",
                "x-width": str(img.width),
                "x-height": str(img.height),
            }

            return Response(
                content=raw_data, media_type="application/octet-stream", headers=headers
            )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------------------
# 7. LIST TILES - LLISTA TOTES LES TESSEL·LES DISPONIBLES
# -------------------------------------------------------------------------

import re


@app.get("/listTiles")
def list_tiles():
    try:
        pattern = re.compile(r"^[NS]\d{2}[EW]\d{3}_cog\.tif$")
        tiles = sorted(
            f[: -len("_cog.tif")]
            for f in os.listdir(COG_FOLDER_PATH)
            if pattern.match(f)
        )
        return {"tiles": tiles}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------------------
# 8. FOOTPRINT - POLÍGON DE CONTORN GLOBAL
# -------------------------------------------------------------------------

_footprint_cache = None


def _parse_tile_name(name: str):
    lat_base = float(name[1:3])
    lon_sign = 1.0 if name[3:4] == "E" else -1.0
    lon_base = float(name[4:7]) * lon_sign
    return lat_base, lon_base


def _add_edge(edges: dict, x1: int, y1: int, x2: int, y2: int):
    rev = f"{x2},{y2}>{x1},{y1}"
    key = f"{x1},{y1}>{x2},{y2}"
    if rev in edges:
        del edges[rev]
    else:
        edges[key] = [x1, y1, x2, y2]


def _build_footprint(tiles: list):
    edges = {}
    for name in tiles:
        lat_base, lon_base = _parse_tile_name(name)
        base_x = round(lon_base * 5)
        base_y = round(lat_base * 5)
        for i in range(5):
            for j in range(5):
                min_x = base_x + j
                max_x = min_x + 1
                min_y = base_y + i
                max_y = min_y + 1
                _add_edge(edges, min_x, min_y, max_x, min_y)
                _add_edge(edges, max_x, min_y, max_x, max_y)
                _add_edge(edges, max_x, max_y, min_x, max_y)
                _add_edge(edges, min_x, max_y, min_x, min_y)

    unused = set(edges.keys())
    rings = []

    while unused:
        first = edges[next(iter(unused))]
        unused.remove(next(iter(unused)))
        ring = [[first[0], first[1]], [first[2], first[3]]]
        cx, cy = first[2], first[3]
        dx, dy = first[2] - first[0], first[3] - first[1]

        while cx != ring[0][0] or cy != ring[0][1]:
            prefs = [(-dy, dx), (dx, dy), (dy, -dx), (-dx, -dy)]
            advanced = False
            for px, py in prefs:
                tx, ty = cx + px, cy + py
                key = f"{cx},{cy}>{tx},{ty}"
                if key in unused:
                    unused.remove(key)
                    cx, cy, dx, dy = tx, ty, px, py
                    ring.append([cx, cy])
                    advanced = True
                    break
            if not advanced:
                break

        if cx == ring[0][0] and cy == ring[0][1] and len(ring) >= 4:
            rings.append([[p[0] / 5.0, p[1] / 5.0] for p in ring])

    def signed_area(r):
        a = 0.0
        for k in range(len(r) - 1):
            a += r[k][0] * r[k + 1][1] - r[k + 1][0] * r[k][1]
        return a / 2.0

    outers = [r for r in rings if signed_area(r) > 0]
    holes = [r for r in rings if signed_area(r) < 0]

    def contains_point(ring, p):
        inside = False
        j = len(ring) - 1
        for i in range(len(ring)):
            xa, ya = ring[i]
            xb, yb = ring[j]
            if (ya > p[1]) != (yb > p[1]) and p[0] < (xb - xa) * (p[1] - ya) / (
                yb - ya
            ) + xa:
                inside = not inside
            j = i
        return inside

    polygons = [[o] for o in outers]
    for h in holes:
        for poly in polygons:
            if contains_point(poly[0], h[0]):
                poly.append(h)
                break

    return {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "properties": {},
                "geometry": {"type": "MultiPolygon", "coordinates": polygons},
            }
        ],
    }


@app.get("/footprint")
def get_footprint():
    global _footprint_cache
    if _footprint_cache is not None:
        return _footprint_cache

    try:
        pattern = re.compile(r"^[NS]\d{2}[EW]\d{3}_cog\.tif$")
        tiles = sorted(
            f[: -len("_cog.tif")]
            for f in os.listdir(COG_FOLDER_PATH)
            if pattern.match(f)
        )
        _footprint_cache = _build_footprint(tiles)
        return _footprint_cache
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
