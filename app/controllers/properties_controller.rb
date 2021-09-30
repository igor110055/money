class PropertiesController < ApplicationController

  before_action :set_property, only: [:edit, :update, :update_amount, :destroy, :delete]
  # after_action :update_all_portfolio_attributes, only: [:create, :destroy]

  # 资产负债列表
  def index
    tags = params[:tags]
    extags = params[:extags]
    if tags
      if mode = params[:mode] and !mode.empty?
        @properties = get_properties_from_tags(tags,extags,mode)
        # 对于非管理员账号不能显示隐藏项目
        if !admin?
          temp = []
          @properties.each do |r|
            temp << r if !r.is_hidden
          end
          @properties = temp
        end
      elsif tags  # 由tag_cloud来的单一标签
        @properties = Property.tagged_with(tags.strip)
      end
      # 计算资产总值以供显示占比使用
      @properties_sum = 0
      @properties.each {|p| @properties_sum += p.amount_to}
    else
      @properties = Property.all_sort admin?
    end
  end

  # 显示火币短线资产
  def huobi_assets
    redirect_to action: :index, tags: get_huobi_acc_id
  end

  # 新建资产表单
  def new
    @property = Property.new
  end

  # 储存新建资产
  def create
    @property = Property.new(property_params)
    if @property.save
      put_notice t(:property_created_ok) + sync_create_property
      back_last_page
    else
      render :new
    end
  end

  # 同步另一台服务器的新建资产
  def sync_create_property
    send_sync_request "#{$host2}sync_create_asset.json#{url_params}"
  end

  # 由外部链接而来新建资产
  def sync_create_asset
    sync_host(Property,nil,true) do
      if !Property.find_by_sync_code(params[:sync_code])
        Property.new(data_params).save
      end
    end
  end

  # 编辑资产表单
  def edit
    if (@property and @property.hidden? and !admin?) or !@property # 非管理员无法编辑隐藏资产
      put_warning t(:property_non_exist)
      go_properties
    end
  end

  # 储存更新资产
  def update
    params[:property][:amount].gsub!(',','')
    params[:property][:sync_code].downcase!
    if @property.update_attributes(property_params)
      put_notice t(:property_updated_ok) + add_id(@property) + add_amount(@property) + ' ' + sync_update_property
      back_last_page
    else
      render action: :edit
    end
  end

  # 同步另一台服务器的资产
  def sync_update_property
    send_sync_request "#{$host2}sync_update_asset.json#{url_params}"
  end

  # 由外部链接而来更新资产
  def sync_update_asset
    sync_host(Property,'sync_code') do
      @rs.update_attributes(data_params)
    end
  end

  # 从列表中快速更新资产金额
  def update_amount
    update_property_amount
    sync_code = Property.find(params[:id]).sync_code
    new_amount = eval("params[:new_amount_#{params[:id]}]")
    put_notice sync_amount(sync_code,new_amount)
  end

  # 同步另一台服务器的资产数值
  def sync_amount( sync_code, new_amount )
    send_sync_request "#{$host2}sync_update_amount.json?key=#{$api_key}&sync_code=#{sync_code}&amount=#{new_amount}"
  end

  # 由外部链接而来更新资产的数值
  def sync_update_amount
    sync_host(Property,'sync_code') do
      @rs.update_attribute(:amount,params[:amount])
    end
  end

  # 删除资产
  def destroy
    @property.destroy
    put_notice t(:property_destroy_ok) + sync_destroy_property(@property.sync_code)
    back_last_page
  end

  # 删除资产
  def delete
    destroy
  end

  # 同步另一台服务器的删除资产
  def sync_destroy_property( sync_code )
    send_sync_request "#{$host2}sync_destroy_asset.json?key=#{$api_key}&sync_code=#{sync_code}"
  end

  # 由外部链接而来更新资产的数值
  def sync_destroy_asset
    sync_host(Property,'sync_code') do
      @rs.destroy
    end
  end

  # 跳转至显示流动性资产总值画面
  def show_flow_assets
    redirect_to action: :index, mode: 'a', pid: 13, portfolio_name: '流动性资产总值', tags: '比特币 以太坊 可投资金'
  end

  private

    # 返回上一页面
    def back_last_page
      session[:path] ? go_back : go_properties
    end

    # 取出特定的某笔数据
    def set_property
      begin
        @property = Property.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        @property = nil
      end
    end

    # 设定栏位安全白名单
    def property_params
      if admin?
        params[:property][:tag_list].gsub!(' ',',') if !params[:property][:tag_list].nil?
        params.require(:property).permit(:name,:sync_code,:amount,:currency_id,:is_hidden,:is_locked,:tag_list)
      else
        params.require(:property).permit(:name,:amount,:currency_id)
      end
    end

    # 组成网址参数
    def url_params
      "?key=#{$api_key}&sync_code=#{params[:property][:sync_code].downcase}&name=#{u(params[:property][:name])}&amount=#{params[:property][:amount]}&currency_id=#{params[:property][:currency_id]}&is_hidden=#{params[:property][:is_hidden]}&is_locked=#{params[:property][:is_locked]}&tag_list=#{u(params[:property][:tag_list])}"
    end

    # 组成数据库参数
    def data_params
      {
        sync_code: params[:sync_code],
        name: params[:name],
        amount: params[:amount],
        currency_id: params[:currency_id],
        is_hidden: params[:is_hidden],
        is_locked: params[:is_locked],
        tag_list: params[:tag_list]
      }
    end

end
