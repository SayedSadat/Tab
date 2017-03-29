#!/bin/bash
while true ; do
  for entr in tabchi-*.sh ; do
    entry="${entr/.sh/}"
    tmux kill-session -t $entry
    rm -rf ~/.telegram-cli/tabchi-*/data/animation/
    rm -rf ~/.telegram-cli/tabchi-*/data/audio/
    rm -rf ~/.telegram-cli/tabchi-*/data/document/
    rm -rf ~/.telegram-cli/tabchi-*/data/photo/
    rm -rf ~/.telegram-cli/tabchi-*/data/sticker/
    rm -rf ~/.telegram-cli/tabchi-*/data/temp/
    rm -rf ~/.telegram-cli/tabchi-*/data/video/
    rm -rf ~/.telegram-cli/tabchi-*/data/voice/
    rm -rf ~/.telegram-cli/tabchi-*/data/profile_photo/
    rm -rf ~/.telegram-cli/tabchi-*/data/thumb/*.jpg
    tmux new-session -d -s $entry "./$entr"
    tmux detach -s $entry
  done
  echo Bots Running!
  sleep 1800
done
