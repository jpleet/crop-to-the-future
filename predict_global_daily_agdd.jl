using JLD;
using NetCDF;

function main()

	rcps = ["rcp45", "rcp85"]
	#rcps = ["rcp45"]

	cmips = ["ACCESS1-0", "CSIRO-Mk3-6-0", "MIROC-ESM", "bcc-csm1-1", 
		"GFDL-CM3", "MIROC-ESM-CHEM", "BNU-ESM", "GFDL-ESM2G", "MIROC5", "CanESM2", 
		"GFDL-ESM2M", "MPI-ESM-LR", "CCSM4", "inmcm4", "MPI-ESM-MR", "CESM1-BGC", 
		"IPSL-CM5A-LR", "MRI-CGCM3", "CNRM-CM5", "IPSL-CM5A-MR", "NorESM1-M"];
	#cmips = ["ACCESS1-0"]

	size(ARGS)[1]==4 ? nothing : throw(AssertionError("Need 4 parameters: tbase, ttop, req_agdd, year"))
	const tbase = parse(Float64, ARGS[1]) + 273.15
	const ttop = parse(Float64, ARGS[2]) + 273.15
	const agdd = parse(Float64, ARGS[3]) + 273.15
	const year = parse(Int64, ARGS[4])

	const data_dir = "/home/ubuntu/nex-gddp/"
	const save_dir = "data/"
	mkpath(save_dir)

	println("Processing models. . .")
	
	grow_count = [zeros(365) for i in 1:1440, t in 1:720];
	counter = 1

	for rcp in rcps

		println(rcp)

		for cmip in cmips

			println(cmip)

			grow_count += process_model(cmip, rcp, year, ttop, tbase, agdd, data_dir)

		end

	end

	println("Formatting results. . .")

	grow_mat = zeros(1440,720, 365);
	for i in 1:1440, j in 1:720
		grow_mat[i,j,:] = grow_count[i,j]
	end
	grow_mat = grow_mat / (size(rcps,1)*size(cmips,1))

	println("Saving results. . .")

	save(string(save_dir, "daily_grow_prob_", year, ".jld"), "grow_prob", grow_mat)

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
    grow_range = (tasmin.>tbase) .& (tasmax.<ttop)
    ((tasmax + tasmin) / 2 - tbase) .* grow_range

end


@everywhere function calc_agdd_growth(gdd_ts::Array{Float64,1}, agdd::Float64)

	grow_range = gdd_ts.>0
    [sum(cumprod(grow_range[i:(i+364)]) .* gdd_ts[i:(i+364)], 1)[1] > agdd for i in 1:365]

end


function process_model(cmip::String, rcp::String, year::Int64, ttop::Float64, tbase::Float64, agdd::Float64, data_dir::String)

	println("\tGetting and processing GDD")
	gdd = cat(3, calc_gdd(cmip, rcp, year, ttop, tbase, data_dir), calc_gdd(cmip, rcp, year+1, ttop, tbase, data_dir))

	println("\tCalculating daily growth")
	pmap(x -> calc_agdd_growth(x, agdd), [gdd[i,t,:] for i in 1:size(gdd)[1], t in 1:size(gdd)[2]])

end


main()