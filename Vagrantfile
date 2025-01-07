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

require 'logger'

logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  sprintf "%5s Vagrantfile: %s\n", severity, msg
})
case ENV.fetch('VAGRANT_LOG', 'error').downcase.to_s
when 'trace'
  logger.level = Logger::TRACE
when 'debug'
  logger.level = Logger::DEBUG
when 'info'
  logger.level = Logger::INFO
when 'warn'
  logger.level = Logger::WARN
when 'error'
  logger.level = Logger::ERROR
when 'fatal'
  logger.level = Logger::FATAL
end

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

def audio_socket_exists?(s)
  return !s.nil? && File.exist?(s) && File.socket?(s)
end
BOX_DIR = File.expand_path(File.dirname(__FILE__))

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false if ENV.fetch('VAGRANT_PACKAGE', false).to_s == 'true'

  # Replace this with your private Vagrant Box name and/or URL
  config.vm.box = "lyraphase-runner/macos-monterey-base"
  config.vm.hostname = "macos-12-1.vagrantup.com"
  config.vm.boot_timeout = 1200

  config.vm.provider :libvirt do |libvirt|
    if ENV.fetch('VAGRANT_LIBVIRT_USE_SESSION', false).to_s.downcase == 'true'
      HOME = ENV.fetch('HOME', '~')
      XDG_DATA_HOME = ENV.fetch('XDG_DATA_HOME', File.join(HOME, '.local', 'share'))
      LIBVIRT_SESSION_HOME_DATA = File.join(XDG_DATA_HOME, 'libvirt', 'images')

      libvirt.qemu_use_session = true
      libvirt.uri = 'qemu:///session'
      libvirt.system_uri = 'qemu:///system'
      libvirt.storage_pool_path = LIBVIRT_SESSION_HOME_DATA
      # Root user must first configure virbr0 & define a libvirt network
      # See: https://vagrant-libvirt.github.io/vagrant-libvirt/examples.html#qemu-session-support
      libvirt.management_network_device = 'virbr0'
    end

    CPU_SOCKETS = 1
    CPU_CORES = 4
    CPU_THREADS = 2
    libvirt.driver = "kvm"
    libvirt.host = ""
    libvirt.connect_via_ssh = false
    libvirt.storage_pool_name = "default"
    # libvirt.disk_bus = "virtio"
    libvirt.disk_bus = "sata"
    libvirt.disk_driver_opts = { cache:'writeback', io:'threads' }
    # Set up TRIM support so qcow2 sparse image doesn't keep growing
    # Reference: https://forums.unraid.net/topic/80691-guide-enable-trim-on-qemu-disk-in-macososx/
    # libvirt.disk_driver_opts = { cache:'writeback', io:'threads' }
    # libvirt.volume =  ## TODO: Figure out if we need to declare volume settings for sata
    # vga device at pci.0 slot 0x01 function 0
    # https://libvirt.org/pci-addresses.html#reserved-addresses
    libvirt.video_type = 'vga'
    # libvirt.video_type = 'virtio'
    libvirt.video_vram = 65536

    # PS/2 Kbd & Mouse do not work on macOS
    ## Note: This did not work with vagrant-libvirt-0.7.0
    ## Had to override with qemuargs (See below)
    # libvirt.inputs = []  # Force NO default PS/2 mouse
    # libvirt.input :type => "tablet", :bus => "usb"
    # libvirt.input :type => "keyboard", :bus => "usb"

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
    # libvirt.vendor = 'GenuineIntel'  ## Not yet supported by Vagrant XML template
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
    # libvirt.clock_timers = [ {name: 'rtc', tickpolicy: 'catchup'},
    #  {name: 'pit', tickpolicy: 'delay'},
    #  {name: 'hpet', present: 'no'}
    # ]

    ## CPU Features

    req_cpu_features = "ssse3,sse4.2"
    opt_cpu_features = "popcnt,avx,aes,xsave,xsaveopt"
    libvirt_cpu_feature_format  = req_cpu_features.split(',').map{ |f|  { name: f, policy: 'require' } }
    libvirt_cpu_feature_format += opt_cpu_features.split(',').map{ |f|  { name: f, policy: 'optional' } }
    libvirt.cpu_features = libvirt_cpu_feature_format

    libvirt.machine_type = "q35"
    libvirt.machine_arch = "x86_64"

    # Serial pty
    # For serial kprintf, set xnu kernel boot-args in OpenCore's config.plist:
    #     debug=0x108 -v serial=3 msgbuf=1048576 serialbaud=115200
    # References:
    #   - https://github.com/acidanthera/bugtracker/issues/1954#issue-1140380896
    #   - https://worthdoingbadly.com/xnuqemu/#providing-boot-args
    #   - https://theapplewiki.com/wiki/Boot-args
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
    # pci.0 slot 0x02.0 taken by pcie-root-port
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "qemu-xhci,id=xhci,addr=0x03.0,p2=4,p3=2"
    # libvirt.qemuargs :value => '{ "driver": "qemu-xhci", "p2": 4, "p3": 2, "id": "xhci", "bus": "pci.1", "addr":"0x02" }'
    ## Caused audio to crackle... seems qemu-xhci is more performant
    # libvirt.qemuargs :value => "nec-usb-xhci,id=xhci,addr=0x1d.0"
    # libvirt.qemuargs :value => "-global"
    # libvirt.qemuargs :value => "nec-usb-xhci.msi=off"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => 'isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc'

    # libvirt.loader = '/usr/share/OVMF/x64/OVMF_CODE.4m.fd' ## Symlinked to edk2 path, but doesn't match libvirtd strict matching
    ## Must match firmware paths in json: /usr/share/qemu/firmware/60-edk2-ovmf-x86_64-4m.json
    libvirt.loader = '/usr/share/edk2/x64/OVMF_CODE.4m.fd'
    # libvirt.nvram = '/var/lib/libvirt/qemu/nvram/lyraphase-runner_macos-12-1_OVMF_VARS-1024x768.fd'
    libvirt.nvram_template = '/usr/share/edk2/x64/OVMF_VARS.4m.fd'
    ## TODO: Try OS package provided versions but Default to pre-packaged .box directory versions
    # libvirt.qemuargs :value => "-drive"
    # libvirt.qemuargs :value => "file=#{BOX_DIR}/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on"
    # libvirt.qemuargs :value => "-drive"
    # libvirt.qemuargs :value => "file=#{BOX_DIR}/OVMF_VARS-1024x768.fd,if=pflash,format=raw,unit=1"

    libvirt.qemuargs :value => "-smbios"
    libvirt.qemuargs :value => "type=2"
    ## TODO: Convert all devices to JSON syntax b/c libvirt now converts all XML to JSON qemu args
    ## Because we use libvirt, we are stuck with JSON now, since everything must now
    ## be specified as JSON to prevent PCI device id conflicts
    ## References:
    ##  - https://forum.level1techs.com/t/error-starting-domain-pcie-root-port-in-use-by-ich9-intel-hda/180287
    ##  - https://www.reddit.com/r/VFIO/comments/13epr5d/comment/jjre9gk/?utm_source=share&utm_medium=web2x&context=3
    PIPEWIRE_REMOTE = ENV.fetch('PIPEWIRE_REMOTE', 'pipewire-0')
    PIPEWIRE_SOCKET = File.join(ENV['XDG_RUNTIME_DIR'], PIPEWIRE_REMOTE) unless ENV['XDG_RUNTIME_DIR'].nil?
    PULSEAUDIO_SOCKET = File.join(ENV['XDG_RUNTIME_DIR'], 'pulse', 'native') unless ENV['XDG_RUNTIME_DIR'].nil?

    if audio_socket_exists?(PIPEWIRE_SOCKET) || audio_socket_exists?(PULSEAUDIO_SOCKET)
      # Default to pulseaudio
      VAGRANT_LIBVIRT_AUDIO_BACKEND = ENV.fetch('VAGRANT_LIBVIRT_AUDIO_BACKEND', 'pulseaudio')
      unless VAGRANT_LIBVIRT_AUDIO_BACKEND == 'none'
        libvirt.qemuargs :value => "-device"
        libvirt.qemuargs :value => "usb-audio,id=usbaudio1,audiodev=snd0,bus=xhci.0"
      end

      logger.debug "---------------------------------------------------------------------"
      logger.debug "config.vm.hostname = #{config.vm.hostname}"
      logger.debug "libvirt.default_prefix = #{libvirt.default_prefix}"
      logger.debug "audio_socket_exists?(PIPEWIRE_SOCKET) = #{audio_socket_exists?(PIPEWIRE_SOCKET)}"
      logger.debug "audio_socket_exists?(PULSEAUDIO_SOCKET) = #{audio_socket_exists?(PULSEAUDIO_SOCKET)}"
      logger.debug "---------------------------------------------------------------------"

      DEFAULT_AUDIODEV_OPTIONS = "in.stream-name=\"macOS Input\",out.stream-name=\"macOS Output\",out.mixing-engine=off,out.fixed-settings=off,timer-period=2500,in.buffer-length=10000,out.buffer-length=10000"

      case VAGRANT_LIBVIRT_AUDIO_BACKEND
      when 'pipewire', 'pw'
        unless audio_socket_exists?(PIPEWIRE_SOCKET)
          logger.error("VAGRANT_LIBVIRT_AUDIO_BACKEND selected pipewire, but socket does not exist: #{PIPEWIRE_SOCKET}")
          logger.error("VAGRANT_LIBVIRT_AUDIO_BACKEND valid values: pw, pipewire, pulse, pulseaudio, none")
          logger.error("To boot the VM without audio, set VAGRANT_LIBVIRT_AUDIO_BACKEND=none")
          raise 'ERROR: could not detect pipewire socket'
        end
        logger.info "Using pipewire audio backend"
        logger.warn "Glitchy or scratchy audio bugs may be present depending on QEMU version"

        libvirt.qemuargs :value => "-audiodev"
        libvirt.qemuargs :value => "id=snd0,driver=pipewire,#{DEFAULT_AUDIODEV_OPTIONS}"
        # libvirt.qemuenv QEMU_AUDIO_DRV: 'pw'
        libvirt.qemuenv PIPEWIRE_DEBUG: 'D'
        libvirt.qemuenv PIPEWIRE_RUNTIME_DIR: ENV.fetch('XDG_RUNTIME_DIR', File.join('run', 'user', '1000'))
      when 'pulseaudio', 'pulse'
        unless audio_socket_exists?(PULSEAUDIO_SOCKET)
          logger.error("VAGRANT_LIBVIRT_AUDIO_BACKEND selected pulseaudio, but socket does not exist: #{PULSEAUDIO_SOCKET}")
          logger.error("VAGRANT_LIBVIRT_AUDIO_BACKEND valid values: pw, pipewire, pulse, pulseaudio, none")
          logger.error("To boot the VM without audio, set VAGRANT_LIBVIRT_AUDIO_BACKEND=none")
          raise 'ERROR: could not detect pulseaudio socket'
        end
        logger.info "Using pulseaudio audio backend"

        # libvirt.qemuargs :value => "-device"
        # libvirt.qemuargs :value => "ich9-usb-uhci1,id=uhci,bus=pcie.0,addr=0x1b.0"
        libvirt.qemuargs :value => "-audiodev"
        libvirt.qemuargs :value => "id=snd0,driver=pa,server=unix:#{PULSEAUDIO_SOCKET},#{DEFAULT_AUDIODEV_OPTIONS}"
        ## No working audio from ich9-intel-hda in macOS Monterey -> use usb-audio instead
        # libvirt.qemuargs :value => "ich9-intel-hda,id=hda1,bus=pcie.0,addr=0x1b.0"
        # libvirt.qemuargs :value => "-device"
        # libvirt.qemuargs :value => "hda-duplex,audiodev=audio1,bus=hda1.0,cad=0"
      when 'none'
        logger.info "Using NO audio backend"
      end
    end
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => "ich9-ahci,id=sata,addr=0x1f.4"
    # Uncomment the following if using older vagrant-libvirt with the
    # mouse/keyboard inputs bug
    # Reference: https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1092#issuecomment-728815017
    # libvirt.inputs = []
    # libvirt.usb_controller :model => "none"
    # If libvirt.input settings don't work... these do
    # See: https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1092#issuecomment-1016003272
    #'-device', '
    #                         '"id":"usb","bus":"pci.0","addr":"0x2"}')
    # libvirt.qemuargs :value => "-usb"
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => '{ "driver": "usb-kbd" }'
    #libvirt.qemuargs :value => '{ "driver": "usb-kbd", "id": "input1", "bus": "usb.0", "port": "2" }'
    libvirt.qemuargs :value => "-device"
    libvirt.qemuargs :value => '{ "driver": "usb-tablet" }'
    #libvirt.qemuargs :value => '{ "driver": "usb-tablet", "id":"input0", "bus":"usb.0","port":"1"}'

   # Network
   # virtio-net-pci at pcie.0 slot 0x04
   libvirt.management_network_pci_bus = '0x00'
   libvirt.management_network_pci_slot = '0x04'
  end

   # Network
  if ENV.fetch('VAGRANT_LIBVIRT_USE_SESSION', false).to_s.downcase == 'true'
    # User must setup the virbr0 default network in qemu:///system for use with
    # qemu:///session, the device must be allowed in /etc/qemu/bridge.conf
    # AND SetUID root bit must be set on qemu-bridge-helper
    # References:
    # - https://wiki.qemu.org/Features/HelperNetworking
    # - https://vagrant-libvirt.github.io/vagrant-libvirt/configuration.html#networks
    # - https://gist.github.com/diffficult/cb8c385e646466b2a3ff129ddb886185#what-to-do-if-default-network-interface-is-not-listed
    # - https://mike42.me/blog/2019-08-how-to-use-the-qemu-bridge-helper-on-debian-10
    # - https://wiki.archlinux.org/title/QEMU#Bridged_networking_using_qemu-bridge-helper
    config.vm.network :public_network, :dev => "virbr0",
      :mode => "bridge",
      :type => "bridge"
  else
    # Ensure nic has bus 0x0 and slot 0x0y, so nic is built-in & App-store works
    # Source: https://github.com/kholia/OSX-KVM/blob/a9b20147deef2ca9ffe43567aba51853a18150f2/macOS-libvirt-Catalina.xml#L141
    config.vm.network :private_network, :type => 'dhcp',
      :autostart => true,
      :bus => '0x00',
      :slot => '0x03'
  end

  # macOS root FS is Read-Only... disable default /vagrant share, re-map to /tmp/vagrant
  config.vm.synced_folder ".", "/vagrant", disabled: true
  do_nfs_export = (ENV.fetch('VAGRANT_NFS_EXPORT', true) == 'true')
  config.vm.synced_folder ".", "/tmp/vagrant", nfs_version: 4, nfs_export: do_nfs_export unless ENV.fetch('VAGRANT_PACKAGE', false) == 'true'
end


