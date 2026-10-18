module PaginationHelper
  # "1–25 of 130" and the page links (first, last and the ones around the current)
  def pagination_nav(page)
    return if page.total_count.zero?

    tag.nav(class: "mt-3 flex flex-wrap items-center justify-between gap-2 text-muted", aria: { label: t("pagination.label") }) do
      tag.span(t("pagination.summary", from: page.first_index, to: page.last_index, count: page.total_count)) +
        (tag.div(class: "flex flex-wrap gap-1") { safe_join(pagination_links(page)) } if page.total_pages > 1)
    end
  end

  private
    def pagination_links(page)
      links = [ pagination_link(page.previous_page, "‹", t("pagination.previous")) ]
      pagination_window(page).each do |number|
        links << if number.nil?
          tag.span("…", class: "px-1.5 py-1")
        elsif number == page.number
          tag.span(number, class: "btn btn-sm border-accent bg-accent-soft text-accent-ink", aria: { current: "page" })
        else
          pagination_link(number, number, t("pagination.page", number: number))
        end
      end
      links << pagination_link(page.next_page, "›", t("pagination.next"))
    end

    def pagination_link(number, label, title)
      return tag.span(label, class: "btn btn-sm opacity-40", aria: { disabled: true }) unless number

      link_to label, url_for(request.query_parameters.merge(page: number)), class: "btn btn-sm", title: title, aria: { label: title }
    end

    def pagination_window(page)
      numbers = ([ 1, page.total_pages ] + (page.number - 2..page.number + 2).to_a).select { |n| n.between?(1, page.total_pages) }.uniq.sort
      numbers.each_cons(2).with_object([ numbers.first ]) do |(a, b), window|
        window << nil if b - a > 1
        window << b
      end
    end
end
