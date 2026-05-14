from pydub import AudioSegment
from pydub.effects import normalize, compress_dynamic_range

# 1) Ruta del teu MP3 original
input_path = "off_track.mp3"

# 2) Ruta del MP3 optimitzat
output_path = "off_track_optimized.mp3"

# 3) Carregar MP3
audio = AudioSegment.from_mp3(input_path)

# 4) Normalitzar a volum màxim
audio = normalize(audio)

# 5) Limitador suau per sonar més alt sense saturar
audio = compress_dynamic_range(
    audio,
    threshold=-10.0,
    ratio=4.0,
    attack=5,
    release=50
)

# 6) Exportar a MP3 128 kbps
audio.export(output_path, format="mp3", bitrate="128k")

print("✔️ So optimitzat generat:", output_path)
