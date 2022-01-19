# -*- mode: ruby -*-
# vi: set ft=ruby :

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

    libvirt.machine_type = "pc-q35-4.2"
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
    libvirt.qemuargs :value => "usb-ehci,id=ehci"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "nec-usb-xhci,id=xhci"
    libvirt.qemuargs :value => "-global"
    libvirt.qemuargs :value => "nec-usb-xhci.msi=off"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => 'isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc'

    ## TODO: How to package & reference these files in Vagrant .box?
    libvirt.loader = '/usr/share/OVMF/OVMF_CODE.fd'
    libvirt.nvram = '/var/lib/libvirt/qemu/nvram/lyraphase-runner_macos-12-1_OVMF_VARS-1024x768.fd'
#    libvirt.qemuargs :value => "-drive"
#    libvirt.qemuargs :value => "file=OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on"
#    libvirt.qemuargs :value => "-drive"
#    libvirt.qemuargs :value => "file=OVMF_VARS-1024x768.fd,if=pflash,format=raw,unit=1"

    libvirt.qemuargs :value => "-smbios"
    libvirt.qemuargs :value => "type=2"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "ich9-intel-hda"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "hda-duplex"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "ich9-ahci,id=sata"

    # If libvirt.input settings don't work... these do
    # See: https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1092#issuecomment-1016003272
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "usb-tablet"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "usb-kbd"
  end

  config.vm.box = "lyraphase-runner/macos-monterey-base"
  config.vm.hostname = "macos-12-1.vagrantup.com"
  config.vm.boot_timeout = 1200
  # macOS root FS is Read-Only... disable default /vagrant share, re-map to /tmp/vagrant
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/tmp/vagrant" unless ENV.fetch('VAGRANT_PACKAGE', false) == 'true'
end


