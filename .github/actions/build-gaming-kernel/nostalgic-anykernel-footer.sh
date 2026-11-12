ui_print " "
ui_print "NostalgiKSU"
ui_print "NOSTALGIC Kernel Lab for OnePlus 13R"
ui_print " "
ui_print "AnyKernel3 by osm0sis @ xda-developers"
ui_print " "
ui_print "NOSTALGIC Kernel Lab"
ui_print "Built with love by NOSTALGIC @Reals3s"
ui_print " "
ui_print "Core stack: NostalgiKSU 33197-6 + NOSTALGIC SuSFS 2.4.0 GKI-2"
ui_print "Channel: https://t.me/RealS3SKernelLab"
ui_print " "
ui_print "Credits: OnePlus OSS, NostalgiKSU contributors and AnyKernel3."

if [ -d "$AKHOME/rekernel-module" ]; then
  ui_print "Installing pinned ReKernel 11.7 companion module..."
  rm -rf /data/adb/modules/re_kernel.new
  mkdir -p /data/adb/modules/re_kernel.new
  cp -af "$AKHOME/rekernel-module/." /data/adb/modules/re_kernel.new/
  chmod 0755 /data/adb/modules/re_kernel.new/post-fs-data.sh
  rm -rf /data/adb/modules/re_kernel
  mv /data/adb/modules/re_kernel.new /data/adb/modules/re_kernel
fi

if [ -d "$AKHOME/nostalgiksu-gaming-module" ]; then
  ui_print "Installing NostalgiKSU Gaming Profile services and diagnostics..."
  rm -rf /data/adb/modules/nostalgiksu_gaming.new
  mkdir -p /data/adb/modules/nostalgiksu_gaming.new
  cp -af "$AKHOME/nostalgiksu-gaming-module/." /data/adb/modules/nostalgiksu_gaming.new/
  chmod 0755 /data/adb/modules/nostalgiksu_gaming.new/*.sh
  rm -rf /data/adb/modules/nostalgiksu_gaming
  mv /data/adb/modules/nostalgiksu_gaming.new /data/adb/modules/nostalgiksu_gaming
fi
