#!/bin/bash
set -e

echo "=== OpenCue Complete Fresh Start ==="

# 2. Install Python components
echo "2. Installing Python components..."
pip install -e ./pycue
pip install -e ./pyoutline
pip install -e ./cuesubmit
pip install -e ./cuegui
pip install -e ./cueadmin
pip install -e ./rqd

# 3. Build Cuebot
echo "3. Building Cuebot..."
cd cuebot
./gradlew clean build

# 4. Set up PostgreSQL database
echo "4. Setting up database..."
sudo -u postgres psql -p 5433 -c "CREATE USER opencue_user WITH PASSWORD 'suju2403' CREATEDB;" 2>/dev/null || true
sudo -u postgres psql -p 5433 -c "CREATE DATABASE opencue_db OWNER opencue_user;" 2>/dev/null || true
sudo -u postgres psql -p 5433 -d opencue_db -c "GRANT ALL ON SCHEMA public TO opencue_user; ALTER SCHEMA public OWNER TO opencue_user;"

# 5. Initialize database schema
echo "5. Initializing database schema..."
cd ..
flyway -url=jdbc:postgresql://localhost:5433/opencue_db \
       -user=opencue_user \
       -password=suju2403 \
       -locations=filesystem:cuebot/src/main/resources/conf/ddl/postgres/migrations \
       migrate

# 6. Load seed data
echo "6. Loading seed data..."
psql -h localhost -p 5433 -U opencue_user -d opencue_db -f cuebot/src/main/resources/conf/ddl/postgres/seed_data.sql

# 7. Create startup scripts
echo "7. Creating startup scripts..."
cat > ~/start_cuebot.sh << 'SCRIPT'
#!/bin/bash
cd ~/Documents/GitHub/OpenCue/cuebot
source ~/Documents/GitHub/opencue-dev/bin/activate
java -jar build/libs/cuebot.jar \
  --datasource.cue-data-source.jdbc-url=jdbc:postgresql://localhost:5433/opencue_db \
  --datasource.cue-data-source.username=opencue_user \
  --datasource.cue-data-source.password=suju2403 \
  --log.frame-log-root.default_os="/tmp/opencue/logs" \
  --spring.main.allow-bean-definition-overriding=true
SCRIPT

cat > ~/start_rqd.sh << 'SCRIPT'
#!/bin/bash
cd ~/Documents/GitHub/OpenCue
source ~/Documents/GitHub/opencue-dev/bin/activate
python -m rqd
SCRIPT

chmod +x ~/start_cuebot.sh ~/start_rqd.sh

echo "=== Fresh Start Complete ==="
echo ""
echo "To start development environment:"
echo "  Terminal 1: ~/start_cuebot.sh"
echo "  Terminal 2: ~/start_rqd.sh"
echo "  Terminal 3: cuegui"
echo ""
echo "Environment variables are set in the scripts."
