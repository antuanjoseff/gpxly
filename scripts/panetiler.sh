# Windows
java -Xmx4g -jar planetiler.jar planetiler_map.yaml --osm=data/sources/local.osm.pbf --output=data/output.pmtiles

# linux
java -Xmx8g -jar planetiler.jar generate-custom   --schema=chatgpt.yaml   --osm-path=catalunya.pbf   --output=catalunya.mbtiles   --force

java -Xmx8g -jar planetiler.jar generate-custom   --schema=chatgpt2.yaml   --osm-path=catalunya.pbf   --output=catalunya2.mbtiles   --force

java -Xmx8g -jar planetiler.jar generate-custom   --schema=chatgpt5.yaml   --osm-path=catalunya.pbf   --output=catalunya5.mbtiles   --force