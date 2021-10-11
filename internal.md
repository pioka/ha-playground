# Pacemaker+DRBDセットアップメモ

* 参考: https://www.clusterlabs.org/pacemaker/doc/deprecated/en-US/Pacemaker/1.1/html-single/Clusters_from_Scratch/index.html
* Hosts
  * ha-node1
      * OS: CentOS 7
      * IP: 192.168.222.91
  * ha-node2
      * OS: CentOS 7
      * IP: 192.168.222.91

```sh
# 以下両系実行
sudo yum install -y pacemaker pcs psmisc policycoreutils-python

sudo firewall-cmd --permanent --add-service=high-availability
sudo firewall-cmd --reload

sudo systemctl start pcsd
sudo systemctl enable pcsd

## 両系で同じパスワードを設定する
sudo passwd hacluster
```

```sh
# 以下片系実行
sudo pcs cluster auth 192.168.222.91 192.168.222.92
sudo pcs cluster setup --name mycluster 192.168.222.91 192.168.222.92
sudo pcs cluster start --all
```

DRBD
```sh
# 以下両系実行
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum install -y kmod-drbd84 drbd84-utils
```

```sh
# on ha-node1
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.222.92" port port="7789" protocol="tcp" accept'
sudo firewall-cmd --reload
```

```sh
# on ha-node2
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
 on ha-node1 {
  disk   /dev/vg01/lvdrbd;
  address  192.168.222.91:7789;
 }
 on ha-node2 {
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
cat /proc/drbd
#>version: 8.4.11-1 (api:1/proto:86-101)
#>GIT-hash: 66145a308421e9c124ec391a7848ac20203bb03c build by #>mockbuild@, 2020-04-05 02:58:18
#>
#> 1: cs:Connected ro:Primary/Secondary ds:UpToDate/UpToDate C #>r-----
#>    ns:4190044 nr:0 dw:0 dr:4192148 al:8 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:0

## フォーマット
sudo mkfs.xfs /dev/drbd1
```

