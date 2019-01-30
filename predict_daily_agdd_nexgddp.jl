using JLD;
using NetCDF;
using Distributed;

addprocs() #prep for multiprocessing pmap

function main()

	# list of all rcp scenarios
	rcps = ["rcp45", "rcp85"]

	# list of all climate models
	cmips = ["ACCESS1-0", "CSIRO-Mk3-6-0", "MIROC-ESM", "bcc-csm1-1", 
		"GFDL-CM3", "MIROC-ESM-CHEM", "BNU-ESM", "GFDL-ESM2G", "MIROC5", "CanESM2", 
		"GFDL-ESM2M", "MPI-ESM-LR", "CCSM4", "inmcm4", "MPI-ESM-MR", "CESM1-BGC", 
		"IPSL-CM5A-LR", "MRI-CGCM3", "CNRM-CM5", "IPSL-CM5A-MR", "NorESM1-M"];

	size(ARGS)[1]==5 ? nothing : throw(AssertionError("Need 4 parameters: tbase, ttop, req_agdd, start_year, end_year"))
	tbase = parse(Float64, ARGS[1]) + 273.15
	ttop = parse(Float64, ARGS[2]) + 273.15
	agdd = parse(Float64, ARGS[3])
	start_year = parse(Int64, ARGS[4])
	end_year = parse(Int64, ARGS[5])

	data_dir = "/home/ubuntu/nex-gddp/"
	save_dir = "data/"
	mkpath(save_dir)

	# go through each model and count number of models where growth is possible
	println("Processing models. . .")

	for year in start_year : end_year

		println(year)
	
		grow_count = [zeros(365) for i in 1:1440, t in 1:720];

		for rcp in rcps

			println(rcp)

			for cmip in cmips

				println(cmip)

				grow_count += process_model(cmip, rcp, year, ttop, tbase, agdd, data_dir)

			end

		end

		println("Saving results. . .")

		save(string(save_dir, "daily_grow_count_", year, ".jld"), "grow_count", grow_count)

	end

end


function calc_gdd(cmip::String, rcp::String, year::Int64, ttop::Float64, tbase::Float64, data_dir::String)

    println(string("\t\tCalculating gdd for year ", year))

    tasmax_f = string(data_dir, "BCSD/", rcp, "/day/atmos/tasmax/r1i1p1/v1.0/tasmax_day_BCSD_", rcp, "_r1i1p1_", cmip, "_", year, ".nc")
    tasmin_f = string(data_dir, "BCSD/", rcp, "/day/atmos/tasmin/r1i1p1/v1.0/tasmin_day_BCSD_", rcp, "_r1i1p1_", cmip, "_", year, ".nc")

    println("\t\tReading tasmax")
    nc_tasmax = NetCDF.open(tasmax_f)
    tasmax = NetCDF.readvar(nc_tasmax, "tasmax")
    NetCDF.close(nc_tasmax)

    println("\t\tReading tasmin")
    nc_tasmin = NetCDF.open(tasmin_f)
    tasmin = NetCDF.readvar(nc_tasmin, "tasmin")
    NetCDF.close(nc_tasmin)

    println("\t\tCalculating gdd")
    max.((tasmax + tasmin) / 2 .- tbase, 0) .* (tasmax.<ttop)

end


@everywhere function calc_agdd_growth(gdd_ts::Array{Float64,1}, agdd::Float64)

	grow_range = gdd_ts.>0
    [sum(cumprod(grow_range[i:(i+364)]) .* gdd_ts[i:(i+364)]) > agdd for i in 1:365]

end


function process_model(cmip::String, rcp::String, year::Int64, ttop::Float64, tbase::Float64, agdd::Float64, data_dir::String)

	println("\tGetting and processing GDD")
	gdd = cat(calc_gdd(cmip, rcp, year, ttop, tbase, data_dir), calc_gdd(cmip, rcp, year+1, ttop, tbase, data_dir), dims=3)

	println("\tCalculating daily growth")
	pmap(x -> calc_agdd_growth(x, agdd), [gdd[i,t,:] for i in 1:size(gdd)[1], t in 1:size(gdd)[2]])

end


main()