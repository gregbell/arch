PHONY: vm-start vm-stop vm-reset clean

archlinux-latest.conf:
	quickget archlinux latest

vm-start: archlinux-latest.conf
	quickemu  --vm archlinux-latest.conf --display spice --public-dir $(PWD)

vm-stop: archlinux-latest.conf
	quickemu  --vm archlinux-latest.conf --kill

vm-reset:
	quickemu --vm archlinux-latest.conf --delete-disk

clean:
	quickemu --vm archlinux-latest.conf --delete-vm
