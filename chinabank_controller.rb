# encoding: utf-8
require 'nokogiri'
require 'open-uri'

class ChinabankController < ApplicationController

  def pay
    base_url = "http://pay3.chinabank.com.cn/PayGate"
    chinabank_params ={};
    chinabank_params['v_amount']    = params[:price] || 0                      #订单总金额
    chinabank_params['v_moneytype'] = "CNY"                                    #币种
    chinabank_params['v_oid']       = (Time.now.to_f).to_s.gsub("\.","")       #订单编号
    chinabank_params['v_mid']       = "1001"                                   #商户编号
    chinabank_params['v_url']       = "http://www.lktz.net:5800/product/paid"  #URL地址
    chinabank_params['key']         = "test"

    params1 = []
    params2 = []
    chinabank_params.each do |k, v|
      params1 << v
      params2 << "#{k}=#{v}"
    end
    v_md5info = Digest::MD5.hexdigest(params1.join("")).upcase    #MD5校验码
    params_str = params2.join("&")

    gw_url = "#{base_url}?#{params_str}&v_md5info=#{v_md5info}"
    
    pay_url = "https://pay3.chinabank.com.cn/Payment.do"
    doc = Nokogiri::HTML(open(gw_url))
    inputs = []
    doc.search('form[@name="PAForm"]/input').each do |input|
        inputs << "#{input['name']}=#{input['value']}"
    end
    url = base_url + "?" + inputs.join("&")

    agent = Mechanize.new
    cert_store = OpenSSL::X509::Store.new

    cert_store.add_file Rails.root.to_s + 'cacert.pem'
    agent.cert_store = cert_store

    page = agent.get url
    form = page.form_with :name => "PAForm"
    result = agent.submit form

    data = []
    result.forms.first.fields.each do |input|
      data << "#{input.name}=#{input.value}" if input.name != "pmode_id"
    end
    bank = params[:bank]
    bank_url = "#{pay_url}?#{data.join('&')}&pmode_id=#{bank}"
    redirect_to bank_url
  end

  def bank_code(code)
    map = {}
    map["icbc"] = 1052
    map["cmb"] = 108
    map["ccb"] = 105
    map["abc"] = 103
    map["boc"] = 104
    map["boc2"] = 3407
    map[""] = 3283
  end
end
