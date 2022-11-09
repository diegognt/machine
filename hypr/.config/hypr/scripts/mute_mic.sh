wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

MIC_LIGHT=$(brightnessctl --device='platform::micmute' get)

echo $MIC_LIGHT

if [[ $MIC_LIGHT -eq 1 ]]; then
  brightnessctl --device='platform::micmute' set 0
elif [[ $MIC_LIGHT = 0 ]]; then
  brightnessctl --device='platform::micmute' set 1
fi
