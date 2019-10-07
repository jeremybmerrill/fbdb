class Impression < ApplicationRecord
	# default_scope { where(most_recent: true)}
	# does this exist?

	# default_sort :most_recent
	default_scope {order( :crawl_date)}
end
