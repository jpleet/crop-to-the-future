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

    #size(ARGS)[1]==7 ? nothing : throw(AssertionError("Wrong parameters"))
    const lon = parse(Float64, ARGS[1])
    const lat = parse(Float64, ARGS[2])
    const tbase = parse(Float64, ARGS[3]) + 273.15
    const ttop = parse(Float64, ARGS[4]) + 273.15
    const agdd = parse(Float64, ARGS[5])
    const year1 = parse(Int64, ARGS[6])
    const year2 = parse(Int64, ARGS[7])
    
    const data_dir = "/home/ubuntu/nex-gddp/"
    const save_dir = "data/"
    mkpath(save_dir)
    mkpath("data/temp")

    # coordinates matching all NetCDF files
    lons = collect(linspace(0.125,359.875,1440))
    lats = collect(linspace(-89.875, 89.875, 720))
    lon_idx = findmin(abs.(lons-lon))[2]
    lat_idx = findmin(abs.(lats-lat))[2]

    grow_count = Array{Int64,1}(0)
    
    for rcp in rcps

        println(rcp)

        for cmip in cmips

            println(cmip)

            pred_prob = process_model(cmip, rcp, year1, year2, lon_idx, lat_idx, tbase, ttop, agdd, data_dir)

            save(string("data/temp/model_", rcp, "_", cmip, "_", lon, "_", lat, ".jld"), "grow_prob", pred_prob)

            if size(grow_count) != size(pred_prob)
                grow_count = pred_prob
            else
                grow_count += pred_prob
            end


        end

    end
    
    println("Saving results. . .")

    save(string(save_dir, "daily_grow_prob_", year1, "_", year2, "_", lon, "_", lat, ".jld"), 
        "grow_prob", grow_count / (size(rcps,1)*size(cmips,1)))

end


function process_model(cmip::String, rcp::String, year1::Int64, year2::Int64, lon_idx::Int64, lat_idx::Int64, tbase::Float64, ttop::Float64, agdd::Float64, data_dir::String)

    gdds = [calc_gdd(cmip, rcp, y, lon_idx, lat_idx, tbase, ttop, data_dir) for y in year1:year2]
    gdds = vcat(gdds...)
    
    grow_range = gdds.>0
    [sum(cumprod(grow_range[i:(i+364)]) .* gdds[i:(i+364)], 1)[1] > agdd for i in 1:(size(gdds,1)-365)]

end


function calc_gdd(cmip::String, rcp::String, year::Int64, lon_idx::Int64, lat_idx::Int64, tbase::Float64, ttop::Float64, data_dir::String)

    println(string("\t\tCalculating gdd for year ", year))

    tasmax_f = string(data_dir, "BCSD/", rcp, "/day/atmos/tasmax/r1i1p1/v1.0/tasmax_day_BCSD_", rcp, "_r1i1p1_", cmip, "_", year, ".nc")
    tasmin_f = string(data_dir, "BCSD/", rcp, "/day/atmos/tasmin/r1i1p1/v1.0/tasmin_day_BCSD_", rcp, "_r1i1p1_", cmip, "_", year, ".nc")

    println("\t\tReading tasmax")
    nc_tasmax = NetCDF.open(tasmax_f)
    tasmax = NetCDF.readvar(nc_tasmax, "tasmax", start=[lon_idx, lat_idx, 1], count=[1,1,-1])
    tasmax = vcat(tasmax...)
    NetCDF.close(nc_tasmax)

    println("\t\tReading tasmin")
    nc_tasmin = NetCDF.open(tasmin_f)
    tasmin = NetCDF.readvar(nc_tasmin, "tasmin", start=[lon_idx, lat_idx, 1], count=[1,1,-1])
    tasmin = vcat(tasmin...)
    NetCDF.close(nc_tasmin)

    println("\t\tCalculating gdd")
    grow_range = (tasmin.>tbase) .& (tasmax.<ttop)
    ((tasmax + tasmin) / 2 - tbase) .* grow_range

end


main()