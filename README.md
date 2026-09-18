------------------------
GET NEW DEM
---

---

URL: https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3

Menú Coordinates.

Un cop seleccionat el model DEM de 30metres i una zona del mapa (màxim 450.000km2) es descarrega un sol arxiu en format .tif

A la carpeta scripts hi ha un arxiu de python (split_tif_to_cog) que divideix aquest arxiu i el converteix a arxius més petits amb format cog/tif. Cada arxiu resultant cobreix una superifie de 1grau de latitud x 1 grau de longitud. Aquests arxius pesen de l'ordre de 60 o 70Mb.

El mateix script converteix aquests arxius a un format cog. Aquest format permet al frontend descarregar-se només una part d'aquests arxius. La part descarregada fa 0.2 graus de latitud x 0.2graus de longitud. Aquests arxius tenen un pes aproximat de 5 o 6 mb

Per afegir noves regions només cal afegir aquests arxius \_cog.tif a la carpeta del servidor arsys (213.165.93.0) a la carpeta /data/apps/mdt/dades_cog i automàticament estaran disponibles a la app la propera vegada que s'executi
