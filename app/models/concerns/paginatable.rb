# Pages of any list: Model.where(...).paginate(params[:page]) returns the
# records of that page and what the page navigation needs
module Paginatable
  extend ActiveSupport::Concern

  PER_PAGE = 25

  Page = Data.define(:records, :number, :total_count, :per_page) do
    def total_pages
      [ (total_count.to_f / per_page).ceil, 1 ].max
    end

    def previous_page
      number - 1 if number > 1
    end

    def next_page
      number + 1 if number < total_pages
    end

    def first_index
      total_count.zero? ? 0 : (number - 1) * per_page + 1
    end

    def last_index
      [ number * per_page, total_count ].min
    end
  end

  class_methods do
    def paginate(page, per: PER_PAGE)
      total = unscope(:order, :limit, :offset).count
      number = page.to_i.clamp(1, [ (total.to_f / per).ceil, 1 ].max)
      Page.new(records: limit(per).offset((number - 1) * per).to_a, number: number, total_count: total, per_page: per)
    end
  end
end
