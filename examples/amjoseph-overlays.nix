#
# Example: amjoseph's overlays
#
# This is a snapshot of my overlays, as of 2024-May-10, to demonstrate what
# you can do with `infuse.nix`.  I won't be updating it and it probably won't
# work with more recent nixpkgs; it's just an example.
#

{ lib ? import <nixpkgs/lib>
, infuse ? import ../. { inherit lib; }
, ...
}:
let
  inherit (infuse.v1) infuse;
in [

  (final: prev: {
    # allow googleearth-pro to use dbus (ugh)
    googleearth-pro.__input.dbus = _: prev.dbus;
  })

  (final: lib.flip infuse {
    # mark evil software as broken, because crazy people keep randomly changing
    # package names in nixpkgs, which causes my overlays to be ignored
    dbus.__output.meta.broken = _: true;
    xdg-dbus-proxy.__output.meta.broken = _: true;
    avahi.__output.meta.broken = _: true;
    libsecret.__output.meta.broken = _: true;
    libappindicator.__output.meta.broken = _: true;
    polkit.__output.meta.broken = _: true;
    systemd.__output.meta.broken = _: true;
    at-spi2-atk.__output.meta.broken = _: true;
    pipewire.__output.meta.broken = _: true;
    pipewire_0_2.__output.meta.broken = _: true;
    libpulseaudio-vanilla.__output.meta.broken = _: true;
    libpulseaudio.__output.meta.broken = _: true;
    pulseaudio.__output.meta.broken = _: true;
    pulseaudioFull.__output.meta.broken = _: true;
    qpaeq.__output.meta.broken = _: true;
    geoclue2.__output.meta.broken = _: true;
    bluez.__output.meta.broken = _: true;
    ibm-sw-tpm2.__output.meta.broken = _: true;
    cargo-auditable.__output.meta.broken = _: true;
  })

  # this must come AFTER the markBroken line so we don't mark libudev-zero as broken
  (final: prev: {
    systemdMinimal = prev.libudev-zero;
    systemd = prev.libudev-zero;
    udev = prev.libudev-zero;
  })

  (final: prev: infuse prev {
    # requires umockdev, which requires udev
    libgudev.__output.doCheck = _: false;
    openssh.__input = {
      etcDir = _: "/etc";
      withKerberos = _: false;
      #linkOpenssl = _: false;
      withFIDO = _: false;
      withPAM = _: false;
      pam = _: null;
    };
    shadow.__input.pam = _: null;
    jdk11.__input.enableGnome2 = _: false;
    jdk17.__input.enableGnome2 = _: false;
    jdk17.__input.enableJavaFX = _: false;  # wants gnome+dbus
    cups.__input.avahi = _: null;
    cups.__input.dbus = _: null;
    sane-backends.__input.avahi = _: null;
    soapyremote.__input.avahi = _: null;
    doas.__input.withPAM = _: false;
    xrdp.__input.systemd = _: null;
    xrdp.__input.pam = _: null;
    freerdp.__input.systemd = _: null;
    procps.__input.withSystemd = _: false;
    liblogging.__input.withSystemd = _: false;
    rsyslog.__input.withSystemd = _: false;
    lvm2.__input.udevSupport = _: false;
    lvm2.__output.configureFlags.__append = [
      "--disable-udev_sync"
      "--enable-udev_rules"
      "--enable-udev-rule-exec-detection"
    ];
  })

  (final: prev: infuse prev {
    atkSupport = _: false;

    avahiSupport = _: false;

    pipewireSupport = _: false;
    withPipewireLib = _: false;

    pulseaudioSupport = _: false;
    withPulseAudio = _: false;
    pulseAudioSupport = _: false;
    pulseSupport = _: false;
    withPulse = _: false;
    usePulseAudio = _: false;
    usePulseaudio = _: false;
    libpulseaudio         = _: null;

    systemdSupport = _: false; enableSystemd = _: false;
    enablePolkit = _: false; withPolkit = _: false; polkitSupport = _: false;
    dbusSupport = _: false;
    withDbus = _: false;

    qt6.dbus.dbusSupport = _: false;
    bluezSupport = _: false;
    pamSupport = _: false;    # getting headaches from util-linux lately

    umockdev = _: null;
  })

  (final: prev: infuse prev {
    secretstorage = _: null;  # for yt-dlp
    withGnome = _: false;
    enableGeoLocation = _: false;

    withLibsecret = _: false;
    openalSupport = _: false;

    # there are too many packages that don't check the withsupport
    # options for these, so we null them out:
    #pcsclite              = _: null;
    libpulseaudio         = _: null;
    aalib                 = _: null;   # broken on powerpc
  })

  (final: prev: infuse prev {
    flite.__input.audioBackend = _: "alsa";
    remmina.__input.at-spi2-core = _: null;
    remmina.__input.libdbusmenu-gtk3 = _: null;
    girara.__input.dbus = _: null;
    libhandy.__input.at-spi2-atk = _: null;
    libhandy.__input.at-spi2-core = _: null;
    electrum.__input.enablePlugins = _: false;
    gpsd.__input.pythonSupport = _: false;
    gpsd.__input.guiSupport = _: false;
    gpsd.__input.dbusSupport = _: false;
    gpsd.__input.minimal = _: true;
    msmtp.__input.withKeyring = _: false;
    libftdi1.__input.docSupport = _: false;    # drags in X11, wtf?
    libdecor.__input.dbus = _: null;
    libdecor.__output.mesonFlags.__append = [ "-Ddbus=disabled" ];
    gtk3.__input.trackerSupport = _: false;
    gtk4.__input.trackerSupport = _: false;
    transmission-remote-gtk.__input.libappindicator = _: null;
    tiny.__input.useOpenSSL = _: false;
    tiny.__input.notificationSupport = _: false;
    xrdp.__input.fuse = _: null;
    sqlite.__input.interactive = _: true;
    notmuch.__input.withEmacs = _: false;
    gnupg24.__input = {
      guiSupport = _: false;
      withTpm2Tss = _: false;
      adns = _: null; bzip2 = _: null; gnutls = _: null; openldap = _: null;
      sqlite = _: null; tpm2-tss = _: null;
    };
    pinentry.__input.enabledFlavors = _: [ "curses" "tty" ];
    qutebrowser.__input.withPdfReader = _: false;
    SDL2.__input.udevSupport = _: false;
    mpv-unwrapped.__input.javascriptSupport = _: false;
    mpv-unwrapped.__input.openalSupport = _: false;
    evince.__input.supportMultimedia = _: false;
    #ripgrep.__input.asciidoctor = _: null;     # drags in all of ruby
    util-linux.__input.translateManpages = _: false;
    claws-mail.__input = {
      enableDbus = _: false;
      enableLdap = _: false;
      enableNetworkManager = _: false;
      enablePluginRavatar = _: false;
      enablePluginNotificationSounds = _: false;
      enablePluginAcpiNotifier = _: false;
      enablePluginClamd = _: false;
      enablePluginLibravatar = _: false;
      enablePluginNotification = _: false;
      enablePluginPerl = _: false;
      enablePluginFancy = _: false;    # webkitgtk; build hog, security risk
      enablePluginPython = _: false;
      enablePluginSpamassassin = _: false;
      enablePluginSpamReport = _: false;
      enablePluginVcalendar = _: false;
    };

    # libcardiacarrest assumes libpulseaudio.meta.license exists
    libcardiacarrest.__output.meta.license = _: [];
    cosmic-applets.__input.pulseaudio = _: final.libcardiacarrest;

    python.__input.packageOverrides = final: prev: infuse prev {
      dnspython.__output.doCheck = _: false;
      dnspython.__output.doInstallCheck = _: false;
      apsw.__output.checkInputs = _: [];
      apsw.__output.doCheck = _: false;
      apsw.__output.doInstallCheck = _: false;
      trio.__output.doCheck = _: false;
      trio.__output.doInstallCheck = _: false;
      prev.python-socks.__output.doCheck = _: false;
      prev.python-socks.__output.doInstallCheck = _: false;
      uvloop.__output.doCheck = _: false;
      uvloop.__output.doInstallCheck = _: false;
      eventlet.__output.doCheck = _: false;
      eventlet.__output.doInstallCheck = _: false;
      cheroot.__output.doCheck = _: false;
      cheroot.__output.doInstallCheck = _: false;
      portend.__output.doCheck = _: false;
      portend.__output.doInstallCheck = _: false;
      twisted.__output.doCheck = _: false;
      twisted.__output.doInstallCheck = _: false;
      secretstorage = _: null;   # for yt-dlp
      btchip = _: null;
      pyscard = _: null;
    };

    xdg-utils.__input.perlPackages.NetDBus = _: null;

    # libgcrypt's "jitter entropy generator" gets fussy if you build
    # it with any optimizations.  I don't trust crap like that.
    libgcrypt.__output.configureFlags.__append = [ "--disable-jent-support" ];

    busybox.__output.patches.__append = [
      ./patches/busybox/modprobe-dirname-flag.patch
    ];

    xrdp.__output = {
      passthru.xorgxrdp.__output = {
        configureFlags.__append = [
          "--without-fuse"
          "--disable-pam"
          "--disable-pamuserpass"
          "--disable-kerberos"
          "--enable-jpeg"
          "--enable-tjpeg"
          "--enable-strict-locations=yes"
          "--disable-silent-rules"
          "--disable-maintainer-mode"
          "--disable-dependency-tracking"
        ];
        postInstall.__append = ''
          cat >> $out/etc/X11/xrdp/xorg.conf <<EOF
          Section "Files"
            ModulePath "${final.xorg.xorgserver}/lib/xorg/modules"
            ModulePath "$out/lib/xorg/modules"
          EndSection
          EOF
        '';
      };
      configureFlags.__append = [
        "--enable-jpeg"
        "--disable-ipv6"
        "--disable-opus"
        "--without-fuse" "--disable-fuse"
        "--disable-pam" "--disable-pam-config" "--disable-pamuserpass"
        "--disable-kerberos"
        "--disable-mp3lame"
        "--disable-pixman"
        "--disable-rdpsndaudin"
        #"--enable-rfxcodec"
        "--disable-rfxcodec"
        "--disable-vsock"
        "--enable-strict-locations=yes"
        "--disable-silent-rules"
        "--disable-maintainer-mode"
        "--disable-dependency-tracking"
      ];
      # xrdp proper
      patches.__append = [
        ./patches/xrdp/allow-to-set-the-path-to-sesman-ini.patch
      ];
      postInstall.__append = ''
        cat >> $out/etc/xrdp/sesman.ini <<EOF
        [Globals]
        ListenAddress=127.0.0.1
        [Security]
        RestrictOutboundClipboard=false
        [Chansrv]
        EnableFuseMount=false
        [ChansrvLogging]
        LogLevel=INFO
        EnableSyslog=false
        EOF
      '';
    };

    lvm2.__output.patches.__append = [
      (final.fetchpatch {
        name = "lvm-lvresize-btrfs-support-from-suse.patch";
        url = "https://code.opensuse.org/package/lvm2/raw/master/f/fate-31841-01_fsadm-add-support-to-resize-check-btrfs-filesystem.patch";
        hash = "sha256-dPbRPkKIgIKnMrdqZp63LRHfw9Yt+KGxiChqtqd4j9M=";
      })
    ];

    skawarePackages.s6-rc.__output.patches.__append = [
      ./patches/s6-rc/0001-doc-s6-rc-compile.html-document-bundle-flattening.patch
      ./patches/s6-rc/0002-doc-define-singleton-bundle-document-special-rules.patch
      ./patches/s6-rc/0003-libs6rc-s6rc_graph_closure.c-add-comments-explaining.patch
      ./patches/s6-rc/0004-s6-rc-update.c-add-define-constants-for-bitflags.patch
      ./patches/s6-rc/0005-s6-rc-update.c-rewrite-O-n-2-loop-as-O-n-complexity.patch
      ./patches/s6-rc/0006-WIP-s6-rc-update.c-add-additional-comments.patch
      #./patches/s6-rc/0007-Revert-Simplify-selfpipe-management.patch
      ./patches/s6-rc/0008-s6-rc-update.c-bugfix-for-failure-to-create-pipe-s6r.patch
      ./patches/s6-rc/0009-add-OLDSTATE_UNPROPAGATED_RESTART.patch
      ./patches/s6-rc/0010-disable-restart-if-acquired-new-dependency-behavior.patch
    ];

    abduco.__output.patches      .__append =  [ ./patches/abduco/dont-use-alternate-buffer.patch ];
    seatd.__output.patches       .__append =  [ ./patches/seatd/seatd-mlockall.patch ];
    wlroots_0_14.__output.patches.__append =  [ ./patches/wlroots/wlroots-mlockall.patch ];
    wlroots_0_16.__output.patches.__append =  [
      ./patches/wlroots/wlroots-mlockall-0.15.1.patch
      ./patches/wlroots/fix-wlroots-issue-3275.patch
    ];
    sway-unwrapped.__output.patches.__append = [ ./patches/sway/sway-custom-keybindings.patch ];
    #tiny.__output.patches          .__append = [ ./patches/tiny/allow-binding-ctrlalt.patch ];
    freerdp.__output.patches       .__append = [ ./patches/freerdp/fix-xwayland-100pct-cpu.patch ];
    ip2unix.__output.patches       .__append = [ ./patches/ip2unix/socket-unlink-fix.patch ];
    ip2unix.__output.doCheck        = false;

    # libredirect has two tests which use system(3), which references /bin/sh (not $PATH or $SHELL); these fail on non-NixOS
    libredirect.__output.doInstallCheck = _: false;

    # same problem as: https://github.com/NixOS/nixpkgs/issues/148106
    #openssh.__output.doCheck = _: false;

    # absurdly bloated test suite, assumes ipv6, tries to start an ssh server, wtf
    curl.__output.doCheck = _: false;
    curl.__output.doInstallCheck = _: false;

    libreoffice-still.__input.unwrapped.__output.doCheck = _: false;
    libreoffice-still.__input.unwrapped.__input.langs = _: ["en-US"];
    libreoffice-still.__input.unwrapped.__input.withHelp = _: false;

    # incredibly slow test suites
    openldap.__output.doCheck = _: false;
    openldap.__output.doInstallCheck = _: false;
    libjxl.__output.doCheck = _: false;
    miniupnpc.__output.doCheck = _: false;
    rav1e.__output.doCheck = _: false;
    gtksourceview4.__output.doCheck = _: false;
    crosvm.__output.doCheck = _: false;
    girara.__output.checkPhase = _: "";

    discount.__output.preConfigure.__append = ''
      substituteInPlace configure.inc --replace 'LDCONFIG=`AC_PATH=/sbin:/usr/sbin:/usr/local/sbin acLookFor ldconfig`' 'LDCONFIG=true'
    '';

    okular.__output.cmakeFlags.__append = [
      "-DFORCE_NOT_REQUIRED_DEPENDENCIES=CHM"
    ];

    mg.__output.patches.__append = [
      ./patches/mg/0001-default-column-mode-enabled.patch
      ./patches/mg/0002-default-no-backups.patch
      ./patches/mg/0003-default-fill-column-at-72.patch
      ./patches/mg/0004-set-_PATH_MG_STARTUP-to-.config-mg-startup.mg.patch
      ./patches/mg/0005-main.c-include-hardwired-key-rebinds-for-h-and.patch
    ];

    eiwd.__output.configureFlags.__append = [ "--disable-wired" ];
    eiwd.__output.patches.__append = [
      ./patches/eiwd/0001-do-not-set-the-locally-administered-bit.patch
      ./patches/eiwd/0002-use-a-startup-time-randomly-generated-value-as-the-p.patch
    ];
    picocom.__output.patches.__append = [
      ./patches/picocom/sane-default-escape-key.patch
      ./patches/picocom/visual-feedback-when-escape-key-is-pressed.patch
    ];

    # unsandboxed builds where librem can see /usr/bin/ccache
    bison.__output.doCheck = _: false;
    bison.__output.doInstallCheck = _: false;

    gst_all_1.gst-plugins-good.__output.mesonFlags.__append = [ "-Daalib=disabled" ];

    # expose p.libhid as libhid
    libhid = _: final.p.libhid;

    # take flashrom from ownerboot
    flashrom = _: final.callPackage ../boot/ownerboot/src/util/flashrom {};

    # take em100 from ownerboot
    em100 = _: final.callPackage ../boot/ownerboot/src/util/em100 {};

    pyradio.__output.postPatch.__append = ''
      substituteInPlace pyradio/radio.py --replace 'CAN_CHECK_FOR_UPDATES = True' 'CAN_CHECK_FOR_UPDATES = False'
    '';

    nixpkgs-manual = _: import ../nixpkgs/doc {
      nixpkgs.revision = "ubik";
      pkgs = final // {
        # jing XML validator has non-source provenance
        jing = final.writeShellScriptBin "jing" "exec true";
      };
    };

    gitk = _: final.git.override { guiSupport = true; };

    rust-stm32 = prev.cargo.override {
      rustc = final.pkgsCross.stm32.buildPackages.rustc;
    };

  } // lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 {
    ectool-grukevin = _: final.callPackage (import ../boot/ownerboot/src/util/ectool { boardName = "kevin"; }) {};

    mesa.__output.env.NIX_CFLAGS_COMPILE.__append = " -march=armv8-a";

  } // lib.optionalAttrs prev.stdenv.hostPlatform.isPower64 {
    python.__input.packageOverrides = final: prev: infuse prev {
      aiohttp.__output.doCheck = _: false;
      aiohttp.__output.doInstallCheck = _: false;
    };
    x265.__output.doCheck = _: false;
    meson.__output.doCheck = _: false;
    meson.__output.doInstallCheck = _: false;
  })
]
