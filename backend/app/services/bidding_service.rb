class BiddingService


	def self.get_free_bid_dates(params)
		bid_values = []
		remaining_dates = []
		clashing_dates = {}
		removed_dates = []
		best_bids = {}
		bid_ids = []
		dates = []
		bids = Bidding.where(:product_id => params[:pid]).order("days DESC")
		bids.each_with_index do |bid, index1|
			bid_ids << bid.id
			temp_dates = []
			temp_best_bids = []
			bids.each_with_index do |bid1, index2|
				if (bid.from_date..bid.to_date).overlaps?(bid1.from_date..bid1.to_date) && index1 != index2
					unless removed_dates.include? bid1.id
						temp_dates.push(bid1.id) 
						temp_best_bids.push( 1000 * (bid1.markup.to_f / 100) * bid1.days )
					end
				end
			end
			temp_dates.push(bid.id)
			temp_best_bids.push( 1000 * (bid.markup.to_f / 100) * bid.days )
			best_bids[bid.id] = temp_best_bids
			temp_dates.each_with_index do |dates, index|
				if index!= temp_best_bids.index(temp_best_bids.max)
					removed_dates << dates
				end
			end
			clashing_dates[bid.id] = temp_dates
		end

		bid_ids.uniq.sort { |x, y| x <=> y }
		removed_dates.uniq.sort { |x, y| x <=> y }
		remaining_dates = bid_ids - removed_dates
		count = 0
		(1..30).each do |d|
			remaining_dates.each do |date|	
				unless d > bids.find(date).from_date.strftime("%d").to_i && d < bids.find(date).to_date.strftime("%d").to_i
					count+=1
				end
			end
			if count == 2
				dates << d
			end
			count = 0
		end
		best_bid=  []
		remaining_dates.each_with_index do |date|
			best_bid << bids.find(date)
		end

		return {"free_dates" => dates, "best_bid" => best_bid}
	end

	def self.get_bid_count(params)

		count = []
		if params
			id = params[:uid]
			Product.where(:id => id).each do |bid|
				temp_count = {}
				temp_count[bid.id] = Bidding.where(:product_id => bid.id).count
				count << temp_count
			end
		elsif
			Product.all.each do |bid|
				temp_count = {}
				temp_count[bid.id] =  Bidding.where(:product_id => bid.id).count
				count << temp_count
			end
		end
		return count
	end

	def self.total_bid_count
		month = {}
		dates = Bidding.where('from_date >= ? and to_date <= ? ', Date.today.beginning_of_month - 1.month, Date.today.beginning_of_month + 4.month).order("from_date ASC")
		temp = []
		count = {}
		
		dates.each do |date|
			unless temp.include? date.from_date.strftime("%m").to_i  
				temp << date.from_date.strftime("%m").to_i 
				count = {}
			end				

			(1..31).each do |d|
				if date.from_date.strftime("%d").to_i <= d and date.to_date.strftime("%d").to_i >= d
					count[d] = count[d].to_i + 1
				end					
				
			end
			month[date.from_date.strftime("%m").to_i] = count
		end
		
		data = []
		month.each do |key, value|
			value.each do |key1, value1|
				temp_data = {}
				temp_data["date"] = Date.new(2018, key, key1)
				temp_data["count"] = value1
				data << temp_data
			end
		end

		return data

	end


end
