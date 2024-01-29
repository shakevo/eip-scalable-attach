# !/bin/bash

# ==============================================================================
# EIP_SCALABLE_ATTACH Created by shakevo
# ==============================================================================

# ------------------------------------------------------------------
# EIP自動アタッチ関数
# 
# summary: 予めプーリングしているEIPを自動アタッチする
# returns: アタッチ成功時0(エラー無し), アタッチ失敗の時1
# ------------------------------------------------------------------
attach_eip()
{
    # スクリプトの配置されているディレクトリパス
    WORK_DIR=$(cd $(dirname $0);pwd)
    # 実行ファイル,ログファイルの絶対パス指定
    WORK_EXEC_FILE="${WORK_DIR}/eip_scalable_attach.sh"
    WORK_LOG_FILE="${WORK_DIR}/eip_scalable_attach.log"

    #
    # (1) データ準備
    #- - - - - - - - - - - - -
    # プールしているEIPのAllocationIDを全て指定する(スペース区切り)
    # eipalloc-0xxxxxxxx(Name:Pooling_EIP_01, 3.114.xxx.xxx)
    # eipalloc-0yyyyyyyy(Name:Pooling_EIP_02, 52.192.yyy.yyy)
    eip_alloc_ids="eipalloc-0xxxxxxxx eipalloc-0yyyyyyyy"

    #-----------------
    # メタデータ取得
    #-----------------
    # インスタンスID取得
    instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    # リージョン取得
    region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')

    # AWS CLIの環境変数AWS_DEFAULT_REGIONを設定する
    export AWS_DEFAULT_REGION=${region}

    # 割り当て可能なEIPを取得(インスタンスIDが割り当てされていないEIP)
    available_alloc_id=$(aws ec2 describe-addresses --allocation-ids ${eip_alloc_ids} | jq -r '[.Addresses[] | select(.InstanceId == null)][0] | .AllocationId')

    #
    # (2) 表示(ロギング)
    #- - - - - - - - - - - - -
    # 日付を書き込み
    now=$(date "+%Y/%m/%d %H:%M:%S")
    echo "--${now}--" >> ${WORK_LOG_FILE} 2>&1
    # 割り当てEIPを書き込み
    echo ${available_alloc_id} >> ${WORK_LOG_FILE} 2>&1

    #
    # (3) 実行
    #- - - - - - - - - - - - -
    # no-allow-reassociationを指定することで上書きされることがなくなり、衝突した場合はエラー(true)が戻り値として返る
    aws ec2 associate-address --instance-id ${instance_id} --allocation-id ${available_alloc_id} --no-allow-reassociation >> ${WORK_LOG_FILE} 2>&1

    # 直前実行したコマンドの終了戻り値のTrue/Falseを判定
    if [ $? != 0 ]; then
        return 1
    fi
    return 0
}

# 合否判定用文字列
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
STATUS="failed"

# EIP割り当て処理が成功するまで繰り返しでコール
# (同時起動による衝突を考慮するため)
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
while [ "${STATUS}" = "failed" ]; do

    # EIP自動アタッチ関数をコール
    attach_eip

    # 成功したら判定用文字列STATUSを更新してループ終了
    if [ "$?" -eq 0 ]; then
        STATUS="succeeded"
    fi

    # 連続実行防止(AutoScalingを想定しているのでExponential Backoff不要)
    sleep 5

done