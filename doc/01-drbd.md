# DRBDインストール

```
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
sudo yum install -y drbd84-utils kmod-drbd84
```



# Pacemaker+DRBDセットアップメモ

DRBD
```sh
# 以下両系実行
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum install -y kmod-drbd84 drbd84-utils
```

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

```sh
# 以下両系実行
## プライマリパーティション, Type: 8E (Linux LVM) でパーティションを切る
sudo cfdisk /dev/sdb

## PV,VG,LVを作る
sudo pvcreate /dev/sdb1
sudo vgcreate vg01 /dev/sdb1
sudo lvcreate -n lvdrbd -l 100%VG vg01

## リソース定義
sudo cat << EOS > /etc/drbd.d/test01.res
resource testresource01 {
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
  disk   /dev/vg01/lvdrbd;
  address  192.168.222.91:7789;
 }
 on node2 {
  disk   /dev/vg01/lvdrbd;
  address  192.168.222.92:7789;
 }
}
EOS

sudo modprobe drbd
sudo drbdadm create-md testresource01
sudo drbdadm up testresource01
```

```sh
# 以下片系実行
## 実行した側の系がprimaryとして認識され、同期が開始される
sudo drbdadm primary --force testresource01

## 状態確認
sudo drbdadm status testresource01
#>testresource01 role:Primary
#>  disk:UpToDate
#>  node2 role:Primary       
#>    peer-disk:UpToDate

## フォーマット(primary系のみ可)
sudo mkfs.xfs /dev/drbd1
```




* http://elrepo.org/tiki/HomePage
* https://linbit.com/drbd-user-guide/drbd-guide-9_0-ja/