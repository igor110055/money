class InterestsController < ApplicationController

  before_action :set_interest, only: [:edit, :update, :destroy, :delete]

  def index
    @interests = Interest.all
    @interest_total_twd = Interest.total
    @interest_total_cny = Interest.total(:cny)
  end

  def new
    @interest = Interest.new
  end

  def edit
  end

  def create
    @interest = Interest.new(interest_params)
    if @interest.save
      put_notice t(:interest_created_ok)
      go_interests
    else
      render :new
    end
  end

  def update
    if @interest.update(interest_params)
      p = @interest.property
      put_notice t(:interest_updated_ok) + ' ' + sync_date_and_rate( p.sync_code, params[:interest][:start_date], params[:interest][:rate] )
      go_interests
    else
      render :edit
    end
  end

  # 同步两个服务器的利息起算日和年利率
  def sync_date_and_rate( sync_code, start_date, rate )
    send_sync_request "#{$host2}sync_interest_info.json?key=#{$api_key}&sync_code=#{sync_code.downcase}&start_date=#{start_date}&rate=#{rate}"
  end

  # 由外部链接而来更新利息起算日和年利率
  def sync_interest_info
    sync_host(Property,'sync_code') do
      Interest.find_by_property_id(@rs.id).update_attributes(
        start_date: params[:start_date],
        rate: params[:rate].to_f
      )
    end
  end

  # 删除利息
  def destroy
    @interest.destroy
    put_notice t(:interest_destroyed_ok)
    go_interests
  end

  # 删除利息
  def delete
    destroy
  end

  private

    def set_interest
      @interest = Interest.find(params[:id])
    end

    def interest_params
      params.require(:interest).permit(:property_id, :start_date, :rate)
    end

end
