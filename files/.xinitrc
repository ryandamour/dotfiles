xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
#xrandr --output HDMI-1-4 --left-of eDP-1 --mode 3440x1440
exec i3 
xhost local:root
