# DRBDセットアップメモ

DRBDパッケージインストール
```sh
# on node1 & node2
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
sudo yum install -y drbd84-utils kmod-drbd84
```

DRBD通信用ポートの穴あけ
```sh
# on node1
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.222.92" port port="7789" protocol="tcp" accept'
sudo firewall-cmd --reload
```

```sh
# on node2
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.222.91" port port="7789" protocol="tcp" accept'
sudo firewall-cmd --reload
```

DRBD用LVMボリューム作成
```sh
# on node1 & node2
## プライマリパーティション, Type: 8E (Linux LVM) でパーティションを切る
sudo cfdisk /dev/sdb

## PV,VG,LVを作る
sudo pvcreate /dev/sdb1
sudo pvdisplay

sudo vgcreate vg01 /dev/sdb1
sudo vgdisplay

sudo lvcreate -n lv01 -l 100%VG vg01
sudo lvdisplay
```

DRBDリソース作成
```sh
# on node1 & node2
## リソース定義
sudo cat << EOS > /etc/drbd.d/r01.res
resource r01 {
 protocol C;
 meta-disk internal;
 device /dev/drbd1;
 syncer {
  verify-alg sha1;
 }
 net {
  allow-two-primaries;
 }
 on node1 {
  disk   /dev/vg01/lv01;
  address  192.168.222.91:7789;
 }
 on node2 {
  disk   /dev/vg01/lv01;
  address  192.168.222.92:7789;
 }
}
EOS
```

リソースセットアップ
```sh
# on node1 & node2
## カーネルモジュールロード, ミラーデバイス作成, リソースup
sudo modprobe drbd
sudo drbdadm create-md r01
sudo drbdadm up r01
```

```sh
# on node1
## node1がprimaryとして認識され、同期が開始される
sudo drbdadm primary --force r01

## 状態確認
sudo drbdadm status r01
#>r01 role:Primary
#>  disk:UpToDate
#>  peer role:Secondary
#>    replication:Established peer-disk:UpToDate

cat /proc/drbd
#>testresource01 role:Primary
#>  disk:UpToDate
#>  node2 role:Primary       
#>    peer-disk:UpToDate
```

いろいろディスク操作してみる
```sh
## フォーマット(primary系のみ可)
sudo mkfs.xfs /dev/drbd1

## マウント(primary系のみ可)
sudo mkdir /mnt/r01
sudo mount /dev/drbd1 /mnt/r01

## なんか書き込んでみる
sudo dd bs=1MB count=128 if=/dev/urandom of=/mnt/r01/128mb_file.bin

## アンマウント
sudo umount /mnt/r01
```

系切り替え  
両方primaryにすることもできるし両方secondaryにすることもできる点に注意)
```sh
### on node1
sudo drbdadm secondary r01
### on node2
sudo drbdadm primary r01
```



参考資料
* http://elrepo.org/tiki/HomePage
* https://clusterlabs.org/pacemaker/doc/deprecated/en-US/Pacemaker/1.1/html-single/Clusters_from_Scratch/index.html