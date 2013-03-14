# encoding: utf-8
class ChinabankController < ApplicationController

  def pay
    base_url = "http://pay3.chinabank.com.cn/PayGate"
    price = params[:price]
    chinabank_params = {};
    v_oid = (Time.now.to_f).to_s.gsub("\.","")
    chinabank_params['v_amount']    = price || 0                               #订单总金额
    chinabank_params['v_moneytype'] = "CNY"                                    #币种
    chinabank_params['v_oid']       = v_oid                                    #订单编号
    chinabank_params['v_mid']       = "22655595"                               #商户编号
    #chinabank_params['v_url']       = "http://www.lktz.net:5800/product/paid"  #URL地址
    chinabank_params['v_url']       = "http://127.0.0.1:3000/product/paid"  #URL地址
    chinabank_params['key']         = "5362SRRI1235231"

    params1 = []
    params2 = []
    chinabank_params.each do |k, v|
      params1 << v
      params2 << "#{k}=#{v}"
    end
    v_md5info = Digest::MD5.hexdigest(params1.join("")).upcase    #MD5校验码

    params_str = params2.join("&")

    remark1 = params[:login]                      #帐号
    product = locate_product(price.to_d)
    remark2 = URI.encode(product)                 #商品名称
    gw_url = "#{base_url}?#{params_str}&v_md5info=#{v_md5info}&remark1=#{remark1}&remark2=#{remark2}"
    
    doc = Nokogiri::HTML(open(gw_url, {
      "User-Agent" => user_agent(),
      "Referer" => "http://www.lktz.net/"
    }))
    inputs = []
    doc.search('form[@name="PAForm"]/input').each do |input|
      inputs << "#{input['name']}=#{input['value']}"
    end
    url = "#{base_url}?#{inputs.join("&")}"

    cert_store = OpenSSL::X509::Store.new
    cert_store.add_file Rails.root.to_s + '/cacert.pem'
    
    agent = Mechanize.new
    agent.user_agent_alias = "Windows IE 9"
    agent.cert_store = cert_store

    Payment.create(:customer => remark1, 
                   :sign => v_md5info,
                   :order_num => v_oid,
                   :status => 0,
                   :total => price.to_d,
                   :goods => product)

    page = agent.get url
    form = page.form_with :name => "PAForm"
    result = agent.submit form

    data = []

    result.forms.first.fields.each do |input|
      name = input.name
      value = (input.value || "").gsub(" ", "")
      data << "#{name}=#{value}" if name != "pmode_id"
    end

    bank = bank_code(params[:bank])
    
    pay_url = "https://pay3.chinabank.com.cn/Payment.do"
    confirm_url = pay_url + "?#{data.join('&')}&pmode_id=#{bank}"
    
    #puts "confirm url => #{confirm_url}"

    redirect_to confirm_url
  end

  def paid
    #{"v_md5all"=>"D4F45B52951ABA2E9325A543C09BB485", 
    # "v_md5info"=>"57f0ea1d90467033dfe0fea0558cb818", MD5
    # "remark1"=>"", 备注1 "v_pmode"=>"\xBD\xA8\xC9\xE8\xD2\xF8\xD0\xD0", 支付银行
    # "remark2"=>"", 备注2 "v_idx"=>"713031484640517342", #订单号
    # "v_md5"=>"00A386295D6A1DEF9FDA4E80E778AC40", MD5加密串
    # "v_pstatus"=>"20", 20(表示支付成功)30(表示支付失败)
    # "v_pstring"=>"֧\xB8\xB6\xB3ɹ\xA6", 支付完成
    # "v_md5str"=>"00A386295D6A1DEF9FDA4E80E778AC40", 订单MD5校验码
    # "v_md5money"=>"75faf5d1879e5e7346791db1a09b5360", 
    # "v_moneytype"=>"CNY", 订单实际支付币种
    # "v_oid"=>"1363225860673088", 商户发送的v_oid订单编号 
    # "v_amount"=>"0.01", 订单总金额
    # "controller"=>"chinabank", "action"=>"paid"}

    puts "#{params.inspect}"
    @remark1 = params[:remark1]
    #@remark2 = URI.decode(params[:remark2])
    @v_oid = params[:v_oid]
    @v_pstatus = params[:v_pstatus]
    @v_idx     = params[:v_idx]
    @v_amount  = params[:v_amount]
    status = @v_pstatus == "20" ? 1 : -1
    payment = Payment.where(:order_num => @v_oid).first
    payment.update_attributes(:status => status) if payment
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

  def bank_code(code)
    map = {}
    map["ICBC"] = 1025
    map["ICBC_2"] = 1023
    map["CMBC"] = 308
    map["CCB"] = 105
    map["ABC"] = 103
    map["BOC"] = 104
    map["BOCOM"] = 3407
    map["HXB"] = 3283
    map["CIB"] = 309
    map["CMSB"] = 305
    map["CMSB_2"] = 3051
    map["GDB"] = 306
    map["PAB"] = 307
    map["SHDB"] = 314
    map["ZXB"] = 313
    map["CEB"] = 312
    map["UP"] = 327
    return map[code]
  end

  def user_agent
    return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.99 Safari/537.22"
  end
end