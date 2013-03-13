# encoding: utf-8
class TenpayController < ApplicationController

  def index
  end

  def pay
    base_url = "https://gw.tenpay.com/gateway/pay.htm"                   #支付网关
    price = params[:price].to_i rescue 0

    tenpay_params = {}
    tenpay_params['bank_type'] = params[:bank] || "DEFAULT"   #银行类型(中介担保时此参数无效)
    tenpay_params['body'] = locate_product(price)
    tenpay_params['buyer_id'] = params[:login]
    tenpay_params['fee_type'] = "1"                                      #币种，1人民币
    tenpay_params['input_charset'] = "utf-8"
    tenpay_params['notify_url'] = "http://www.lktz.net:5800/product/notify"
    tenpay_params['out_trade_no'] = (Time.now.to_f).to_s.gsub("\.","")   #商家订单号
    tenpay_params['partner'] = "1215635801"                              #商户号
    tenpay_params['return_url'] = "http://www.lktz.net:5800/product/paid"
    tenpay_params['sign_key_index'] = "1"                                #密钥序号
    tenpay_params['sign_type'] = "MD5"                                   #签名类型,默认：MD5
    tenpay_params['spbill_create_ip'] = request.remote_ip                #用户的公网ip，不是商户服务器IP
    #tenpay_params['subject'] = "股指"                                     #商品名称(中介交易时必填)
    tenpay_params['total_fee'] = params[:price] || 0               #商品金额,以分为单位
    
    params2 = []
    tenpay_params.each do |key, value|
      params2 << "#{key}=#{value}"
    end

    params_str = params2.join("&") 

    md5_sign = tenpay_sign(params_str + "&key=c5b0b6b1f3c45e3b70ce83396895f08d")
    params_str = "#{params_str}&sign=#{md5_sign}"

    redirect_to "#{base_url}?#{params_str}"
  end


  def paid
    # params.inspect = {"bank_billno"=>"201303128145873", "bank_type"=>"1081", 
    # "discount"=>"0", "fee_type"=>"1", "input_charset"=>"utf-8", 
    # "notify_id"=>"GMvrDRC6SAwA_OjCRYzV9UcUSDfPOQLKwG6NhhjvixWI3Prd3vgqJxLAiI_w2rgdvf6yJZr32DyH0TRWr2nIPY7826ZACvH5", 
    # "out_trade_no"=>"13630638622252069", "partner"=>"1215635801", "product_fee"=>"1", 
    # "sign_type"=>"MD5", "time_end"=>"20130312125254", "total_fee"=>"1", "trade_mode"=>"1", 
    # "trade_state"=>"0", "transaction_id"=>"1215635801201303120237829222", "transport_fee"=>"0", 
    # "sign"=>"FFF2644D575217E389E58F353BEF9383", "controller"=>"tenpay", "action"=>"paid"}
    @bank_billno    = params[:bank_billno]
    @transaction_id = params[:transaction_id]
    @total_fee      = params[:total_fee]

  end

  def notify
    # params.inspect =  {"bank_billno"=>"201303128145873", "bank_type"=>"0", "discount"=>"0", 
    # "fee_type"=>"1", "input_charset"=>"utf-8", "notify_id"=>"GMvrDRC6SAwA_OjCRYzV9UcUSDfPOQLKwG6NhhjvixWI3Prd3vgqJ1MqUUj_urBpjut_v-RoDx8atgYb9L-GIMmFGPXKlRoA", 
    # "out_trade_no"=>"13630638622252069", "partner"=>"1215635801", "product_fee"=>"1", 
    # "sign_type"=>"MD5", "time_end"=>"20130312125254", "total_fee"=>"1", "trade_mode"=>"1", 
    # "trade_state"=>"0", "transaction_id"=>"1215635801201303120237829222", "transport_fee"=>"0", 
    # "sign"=>"90E7DDF418F623505438ABD600622E90", "controller"=>"tenpay", "action"=>"notify"}

    puts "in notify method #{params.inspect}"
  end


  def locate_product(price)
    if (price > 0 && price <= 100)
      "雷凯交易期货系统（测试支付）"
      "LeiKai Trading System Trival Edition"
    elsif price > 100 && price <= 1000000
      "雷凯期货交易系统（含光盘、说明书、售后服务卡）"
      "LeiKai Trading System Personal Edition"
    elsif price > 1000000 && price <= 5000000
      "雷凯期货柜员系统（含光盘、说明书、售后服务卡）"
      "LeiKai Trading System Professional Edition"
    else
      "雷凯期货风险监控系统（含光盘、说明书、售后服务卡）"
      "LeiKai Trading System Advanced Edition"
    end 
  end

  def tenpay_sign(params_str)
    Digest::MD5.hexdigest(params_str).upcase
  end

  def bank_map
    map = {}
    map["1001"] = "招商银行借记卡"
    map["1002"] = "中国工商银行"
    map["1003"] = "中国建设银行"
    map["1004"] = "上海浦东发展银行"
    map["1005"] = "中国农业银行"
    map["1006"] = "中国民生银行"
    map["1008"] = "深圳发展银行"
    map["1009"] = "兴业银行"
    map["1010"] = "平安银行"
    map["1020"] = "交通银行"
    map["1021"] = "中信银行"
    map["1022"] = "中国光大银行"
    map["1024"] = "上海银行"
    map["1025"] = "华夏银行"
    map["1027"] = "广东发展银行"
    map["1028"] = "中国邮政储蓄银行（仅支持广东地区）"
    map["1038"] = "招商银行信用卡，招行限额499元"
    map["1032"] = "北京银行"
    map["1033"] = "网汇通"
    map["1052"] = "中国银行"

    return map
  end
end
