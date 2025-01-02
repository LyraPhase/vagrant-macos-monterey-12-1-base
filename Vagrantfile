# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant-macos-monterey-12-1-base Vagrant Box definition
# Copyright (C) © 🄯 2022 James Cuzella
# Copyright (C) © 🄯 2022 LyraPhase LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false if ENV.fetch('VAGRANT_PACKAGE', false) == 'true'

  config.vm.provider :libvirt do |libvirt|

    CPU_SOCKETS = 1
    CPU_CORES = 4
    CPU_THREADS = 2
    libvirt.driver = "kvm"
    libvirt.host = ""
    libvirt.connect_via_ssh = false
    libvirt.storage_pool_name = "default"
#    libvirt.disk_bus = "virtio"
    libvirt.disk_bus = "sata"
    libvirt.disk_driver_opts = { cache:'writeback', io:'threads' }
    #libvirt.volume =  ## TODO: Figure out if we need to declare volume settings for sata
    libvirt.video_type = 'vga'
    libvirt.video_vram = 65536

    # PS/2 Kbd & Mouse do not work on macOS
    ## Note: This did not work with vagrant-libvirt-0.7.0
    ## Had to override with qemuargs (See below)
    #libvirt.inputs = []  # Force NO default PS/2 mouse
    #libvirt.input :type => "tablet", :bus => "usb"
    #libvirt.input :type => "keyboard", :bus => "usb"

    # Spice VMC via unix socket
    libvirt.graphics_type = 'spice'
    libvirt.graphics_autoport = 'yes'
    libvirt.channels = [ { type: 'unix',
      target_type: 'virtio',
      target_name: 'org.qemu.guest_agent.0',
    } ]

    libvirt.memory = 4096
    libvirt.cpus = CPU_SOCKETS * CPU_CORES * CPU_THREADS
    libvirt.features = ['acpi','apic']

    libvirt.cpu_mode = 'custom'
    libvirt.cpu_model = 'Penryn'
#    libvirt.vendor = 'GenuineIntel'  ## Not yet supported by Vagrant XML template
    libvirt.cputopology :sockets => CPU_SOCKETS, :cores => CPU_CORES, :threads => CPU_THREADS

    # USB
    libvirt.usbctl_dev = { model: 'ich9-ehci1' }

    # Clocks
    libvirt.clock_offset = 'localtime'
    libvirt.clock_timer :name => 'rtc', :tickpolicy => 'catchup'
    libvirt.clock_timer :name => 'pit', :tickpolicy => 'delay'
    libvirt.clock_timer :name => 'hpet', :present => 'no'

    ## This way of declaring clock_timers resulted in duplicated clocks
     ## ¯\_(ツ)_/¯
    #libvirt.clock_timers = [ {name: 'rtc', tickpolicy: 'catchup'},
    #  {name: 'pit', tickpolicy: 'delay'},
    #  {name: 'hpet', present: 'no'}
    #]

    ## CPU Features

    req_cpu_features = "ssse3,sse4.2"
    opt_cpu_features = "popcnt,avx,aes,xsave,xsaveopt"
    libvirt_cpu_feature_format  = req_cpu_features.split(',').map{ |f|  { name: f, policy: 'require' } }
    libvirt_cpu_feature_format += opt_cpu_features.split(',').map{ |f|  { name: f, policy: 'optional' } }
    libvirt.cpu_features = libvirt_cpu_feature_format

    libvirt.machine_type = "q35"
    libvirt.machine_arch = "x86_64"

    # Serial pty
    libvirt.serials = [ { type: 'pty' } ]

    # qemu-system-x86_64 -cpu
    #   +kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc,+pcid,+popcnt,+avx,+avx2,+aes,+fma,+fma4,+bmi1,+bmi2,+xsave,+xsaveopt,check
    # libvirt.qemuargs :value => "-cpu"
    # libvirt.qemuargs :value => "Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,#{cpu_features}"

    # man qemu-system-x86_64
    #   -smp [cpus=]n[,cores=cores][,threads=threads][,dies=dies][,sockets=sockets][,maxcpus=maxcpus]
    libvirt.qemuargs :value => "-smp"
    libvirt.qemuargs :value => "cores=#{CPU_CORES},threads=#{CPU_THREADS},sockets=#{CPU_SOCKETS}"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "usb-ehci,id=ehci,addr=0x1c.0"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "qemu-xhci,id=xhci,addr=0x1d.0,p2=4,p3=2"
## Caused audio to crackle... seems qemu-xhci is more performant
#    libvirt.qemuargs :value => "nec-usb-xhci,id=xhci,addr=0x1d.0"
#    libvirt.qemuargs :value => "-global"
#    libvirt.qemuargs :value => "nec-usb-xhci.msi=off"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => 'isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc'

    #libvirt.loader = '/usr/share/OVMF/x64/OVMF_CODE.4m.fd' ## Symlinked to edk2 path, but doesn't match libvirtd strict matching
    ## Must match firmware paths in json: /usr/share/qemu/firmware/60-edk2-ovmf-x86_64-4m.json
    libvirt.loader = '/usr/share/edk2/x64/OVMF_CODE.4m.fd'
    #libvirt.nvram = '/var/lib/libvirt/qemu/nvram/lyraphase-runner_macos-12-1_OVMF_VARS-1024x768.fd'
    #libvirt.nvram_template = '/usr/share/OVMF/x64/OVMF_VARS.4m.fd'
#    libvirt.qemuargs :value => "-drive"
#    libvirt.qemuargs :value => "file=OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on"
#    libvirt.qemuargs :value => "-drive"
#    libvirt.qemuargs :value => "file=OVMF_VARS-1024x768.fd,if=pflash,format=raw,unit=1"

    libvirt.qemuargs :value => "-smbios"
    libvirt.qemuargs :value => "type=2"

    PULSEAUDIO_SOCKET = File.join(ENV['XDG_RUNTIME_DIR'], 'pulse', 'native') unless ENV['XDG_RUNTIME_DIR'].nil?

    if !PULSEAUDIO_SOCKET.nil? && File.exist?(PULSEAUDIO_SOCKET) && File.socket?(PULSEAUDIO_SOCKET)
      # libvirt.qemuargs :value => "-device"
      # libvirt.qemuargs :value => "ich9-usb-uhci1,id=uhci,bus=pcie.0,addr=0x1b.0"
      libvirt.qemuargs :value => "-audiodev"
      libvirt.qemuargs :value => "id=snd0,driver=pa,server=unix:#{PULSEAUDIO_SOCKET},in.stream-name=\"macOS Input\",out.stream-name=\"macOS Output\",out.mixing-engine=off,timer-period=2500,in.buffer-length=10000,out.buffer-length=10000"
      libvirt.qemuargs :value => "-device"
      libvirt.qemuargs :value => "usb-audio,id=usbaudio1,audiodev=snd0,bus=xhci.0"
## No working audio from ich9-intel-hda in macOS Monterey -> use usb-audio instead
#      libvirt.qemuargs :value => "ich9-intel-hda,id=hda1,bus=pcie.0,addr=0x1b.0"
#      libvirt.qemuargs :value => "-device"
#      libvirt.qemuargs :value => "hda-duplex,audiodev=audio1,bus=hda1.0,cad=0"
    end
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "ich9-ahci,id=sata,addr=0x1f.4"

    # If libvirt.input settings don't work... these do
    # See: https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1092#issuecomment-1016003272
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "usb-tablet"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "usb-kbd"

   # Network
   libvirt.management_network_pci_bus = '0x00'
   libvirt.management_network_pci_slot = '0x04'
  end

   # Network
   # Ensure nic has bus 0x0 and slot 0x0y, so nic is built-in & App-store works
   # Source: https://github.com/kholia/OSX-KVM/blob/a9b20147deef2ca9ffe43567aba51853a18150f2/macOS-libvirt-Catalina.xml#L141
   config.vm.network :private_network, :type => 'dhcp',
     :autostart => true,
     :bus => '0x00',
     :slot => '0x03'

#    config.vm.network :public_network, :dev => "virbr1",
#      :mode => "bridge",
#      :type => "bridge"

  # Replace this with your private Vagrant Box name and/or URL
  config.vm.box = "lyraphase-runner/macos-monterey-base"
  config.vm.hostname = "macos-12-1.vagrantup.com"
  config.vm.boot_timeout = 1200
  # macOS root FS is Read-Only... disable default /vagrant share, re-map to /tmp/vagrant
  config.vm.synced_folder ".", "/vagrant", disabled: true
  do_nfs_export = (ENV.fetch('VAGRANT_NFS_EXPORT', true) == 'true')
  config.vm.synced_folder ".", "/tmp/vagrant", nfs_version: 4, nfs_export: do_nfs_export unless ENV.fetch('VAGRANT_PACKAGE', false) == 'true'
end


