.PHONY: sim build run all release run-release export

SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin
PRG=/workspace/no-track-run-watch/bin/notrackrunwatch.prg
PRG_RELEASE=/workspace/no-track-run-watch/bin/notrackrunwatch-release.prg
IQ=/workspace/no-track-run-watch/bin/notrackrunwatch.iq
JUNGLE=/workspace/no-track-run-watch/monkey.jungle
KEY=/workspace/developer_key
JAVA=java -Xms1g -Dfile.encoding=UTF-8 -jar $(SDK)/monkeybrains.jar
DEVICE=fr245

sim:
	$(SDK)/simulator

dev:
	$(JAVA) -o $(PRG) -f $(JUNGLE) -y $(KEY) -d $(DEVICE) -l1 -w

run-dev:
	$(SDK)/monkeydo $(PRG) $(DEVICE)

# Build optimisé pour un appareil (même flags que le debug, plus -r)
release:
	$(JAVA) -o $(PRG_RELEASE) -f $(JUNGLE) -y $(KEY) -d $(DEVICE) -l1 -w -r

run-release:
	$(SDK)/monkeydo $(PRG_RELEASE) $(DEVICE)

# Paquet .iq pour le Connect IQ Store (tous les appareils du manifeste)
export:
	$(JAVA) -o $(IQ) -f $(JUNGLE) -y $(KEY) -e -r -l1 -w