PHONY: vm-start vm-stop clean

archlinux-latest.conf:
	quickget archlinux latest

vm-start: archlinux-latest.conf
	quickemu  --vm archlinux-latest.conf --display spice --public-dir $(PWD)

vm-stop: archlinux-latest.conf
	quickemu  --vm archlinux-latest.conf --kill

clean:
	quickemu --vm archlinux-latest.conf --delete-vm
