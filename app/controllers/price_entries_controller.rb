# Lets you add and remove the manual prices that the ticker cycles through.
class PriceEntriesController < ApplicationController
  def index
    @price_entry = PriceEntry.new(metal: params[:metal].presence_in(PriceEntry::METALS) || "gold")
    load_entries
  end

  def create
    @price_entry = PriceEntry.new(price_entry_params)

    if @price_entry.save
      redirect_to price_entries_path(metal: @price_entry.metal),
                  notice: "#{@price_entry.metal.capitalize} price added."
    else
      load_entries
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    entry = PriceEntry.find(params[:id])
    entry.destroy
    redirect_to price_entries_path, notice: "#{entry.metal.capitalize} price removed."
  end

  private

  # Strong parameters: only these three fields may come from the form.
  def price_entry_params
    params.expect(price_entry: [ :metal, :price_inr, :price_usd ])
  end

  def load_entries
    @entries = PriceEntry.in_cycle_order.group_by(&:metal)
  end
end
