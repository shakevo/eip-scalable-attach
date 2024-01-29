# eip-scalable-attach  
EC2 AutoScalingGroupにElasticIPアドレスを自動的にアタッチするシェルスクリプトです。  
任意のディレクトリに設置して使用することが出来ます。

## 利用ケース
AutoScalingGroupでスケールアウトされたインスタンスに対し、  
固定化された接続情報(PublicIP)が必要になった場合。  

## 実行の前提条件
・Amazon Linux2、かつ jqをインストール済み  
・AWS側で、このシェル実行に利用されるEIPを予めプーリングしておく  
・必要なプーリングEIPの数は、スケールアウトの最大数*2  
・eip_alloc_idsは任意のID指定に書き換える  
・シェルの権限は700とする  
・AutoScalingGroup内にスケールイン/スケールアウトされるインスタンスに設置しておく  
・シェルを設置するインスタンスには、EC2ロールを付与しておく  
・シェルは以下のようにサービス化し、かつ自動起動をONにした状態で使用します
```sh
[root@ip-172-xxx-xxx-xxx ec2-user]# vi /etc/systemd/system/eip_scalable_attach.service

[Unit]
After=network-online.target

[Service]
User=root
ExecStart=/home/ec2-user/eip_scalable_attach/eip_scalable_attach.sh

[Install]
WantedBy=multi-user.target

[root@ip-172-xxx-xxx-xxx ec2-user]# systemctl enable eip_scalable_attach.service
[root@ip-172-xxx-xxx-xxx system]# systemctl is-enabled eip_scalable_attach.service
enabled
```

## 実行の注意点
・そもそもAutoScalingGroup内のインスタンスに対しIPを固定化することがスマートとは言えない  
・eip_alloc_idsは、スペース区切りで複数指定できる  
