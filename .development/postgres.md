# Set environment variables
export OPENCUE_DB_HOST=localhost
export OPENCUE_DB_PORT=5433
export OPENCUE_DB_NAME=opencue_db
export OPENCUE_DB_USER=opencue_user
export OPENCUE_DB_PASS=suju2403

# Verify they're set
echo $OPENCUE_DB_HOST
echo $OPENCUE_DB_PORT

export DB_HOST=localhost:5433
export DB_NAME=opencue_db
export DB_USER=opencue_user
export DB_PASS=opencue_password123

source ~/Documents/GitHub/opencue-dev/bin/activate


/home/didi/Documents/GitHub/OpenCue/.development/fresh_start_opencue.sh 
/home/didi/Documents/GitHub/OpenCue/.development/start_cuebot.sh

chmod +x /home/didi/Documents/GitHub/OpenCue/.development/fresh_start_opencue.sh
