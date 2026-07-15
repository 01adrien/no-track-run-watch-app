

SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin
PRG=/workspace/no-track-run-watch/bin/notrackrunwatch.prg
JUNGLE=/workspace/no-track-run-watch/monkey.jungle
KEY=/workspace/developer_key
DEVICE=epix2pro47mm

sim:
	$(SDK)/simulator

build:
	java -Xms1g -Dfile.encoding=UTF-8 -jar $(SDK)/monkeybrains.jar -o $(PRG) -f $(JUNGLE) -y $(KEY) -d $(DEVICE) -w

run:
	$(SDK)/monkeydo $(PRG) $(DEVICE)

all: build run