#!/bin/bash
cd ~/Documents/GitHub/OpenCue/cuebot
source ~/Documents/GitHub/opencue-dev/bin/activate
java -jar build/libs/cuebot.jar \
  --datasource.cue-data-source.jdbc-url=jdbc:postgresql://localhost:5433/opencue_db \
  --datasource.cue-data-source.username=opencue_user \
  --datasource.cue-data-source.password=suju2403 \
  --log.frame-log-root.default_os="/tmp/opencue/logs" \
  --spring.main.allow-bean-definition-overriding=true