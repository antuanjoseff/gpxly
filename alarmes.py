import numpy as np
from scipy.io.wavfile import write

SAMPLE_RATE = 44100

def save_wav(name, data):
    data = np.int16(data / np.max(np.abs(data)) * 32767)
    write(name, SAMPLE_RATE, data)
    print(f"Generated: {name}")

def beep(freq, duration):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
    return np.sin(2 * np.pi * freq * t)

def sweep(f1, f2, duration):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
    freqs = np.linspace(f1, f2, t.size)
    return np.sin(2 * np.pi * freqs * t)

# 1) ALARM_BEEP_HIGH
def alarm_beep_high():
    b1 = beep(1800, 0.4)
    s1 = np.zeros(int(SAMPLE_RATE * 0.2))
    b2 = beep(2600, 0.4)
    s2 = np.zeros(int(SAMPLE_RATE * 0.2))
    return np.concatenate([b1, s1, b2, s2])

# 2) ALARM_SIREN_SWEEP
def alarm_siren_sweep():
    up = sweep(900, 2400, 1.2)
    down = sweep(2400, 900, 1.2)
    return np.concatenate([up, down])

# 3) ALARM_DIGITAL_PIERCE
def alarm_digital_pierce():
    pulses = []
    for _ in range(20):
        pulses.append(beep(3100, 0.04))
        pulses.append(np.zeros(int(SAMPLE_RATE * 0.03)))
    return np.concatenate(pulses)

# 4) ALARM_METAL_CLANG
def alarm_metal_clang():
    noise = np.random.randn(int(SAMPLE_RATE * 0.9))
    filt = np.exp(-np.linspace(0, 5, noise.size))  # decay
    return noise * filt

# 5) ALARM_TRIPLE_BEEP
def alarm_triple_beep():
    b1 = beep(1500, 0.2)
    p1 = np.zeros(int(SAMPLE_RATE * 0.15))
    b2 = beep(2000, 0.2)
    p2 = np.zeros(int(SAMPLE_RATE * 0.15))
    b3 = beep(2500, 0.2)
    return np.concatenate([b1, p1, b2, p2, b3])

# Generate all
save_wav("ALARM_BEEP_HIGH.wav", alarm_beep_high())
save_wav("ALARM_SIREN_SWEEP.wav", alarm_siren_sweep())
save_wav("ALARM_DIGITAL_PIERCE.wav", alarm_digital_pierce())
save_wav("ALARM_METAL_CLANG.wav", alarm_metal_clang())
save_wav("ALARM_TRIPLE_BEEP.wav", alarm_triple_beep())
