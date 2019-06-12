# Crop to the Future

Predicting crop growth with NASA's [NEX-GDDP](https://cds.nccs.nasa.gov/nex-gddp/) climate projections. Animations in [examples](examples/) show where and when some crops will likely grow worldwide between 2090 and 2099. This is a lot of data crunching (and starts getting expensive), I'm slowly processing examples.

## Plant Biology

Plant growth, from seed to maturity, can be estimated by adding Growing Degree-Day ([GDD](https://en.wikipedia.org/wiki/Growing_degree-day)) values. GDD measures how much heat a plant experiences in a day of a growing season, simply calculated by: ![gdd](https://latex.codecogs.com/gif.latex?GDD%20%3D%20max%28%28Tmax+Tmin%29/2%20-%20Tbase%2C%200%29)  
Where *Tmin* is the minimum daily temperature, *Tmax* is the maximum daily temperature, and *Tbase* is a base temperature above which the plant grows. The GDD equation is extended to incorporate a critical *top temperature*, above which plants cannot survive, to handle possible projections of extremely hot temperatures. ![gdd2](https://latex.codecogs.com/gif.latex?GDD%20%3D%20max%28%28Tmax+Tmin%29/2%20-%20Tbase%2C%200%29%20%5Ctimes%20%28Tmax%20%3C%20Ttop%29)  
The base temperature and top temperature values are known for many different plant species. 

Accumulated GDD (AGDD) is the sum of consecutive non-zero GDDs and represents the amount of heat a plant would experience in a growing season. Studies have matched AGDD values to the stage of development for many plants. In [wheat (Hard Red)](http://msuextension.org/publications/AgandNaturalResources/MT200103AG.pdf), for instance, leaf tips start emerging from the ground at about 145 AGDD and the plant fully matures at about 1665 AGDD. **Crop to the Future** uses NASA's climate projections to calculate AGDDs and predict where plants could grow.

## Global Climate Projections (NEX-GDDP)

The NEX-GDDP dataset contains 21 climate models under 2 greenhouse gas scenarios. Each of the 42 models forecast daily minumum and maximum temperatures for small grids of about 25km x 25km across the globe up until the year 2099 (about 12TB of data).

For a given plant and NEX model, the GDD is calculated for every day of a year in each grid cell. Then, at every day in each grid cell, the GDD is accumulated for the next 365 days, with the accumulation stopping if the GDD is zero. The given plant is assumed to be able to reach maturity on days where the AGDD is above the maturity threshold. The probability of growth in a cell is the number of NEX models where growth is possible out of all the models.

## Examples

### Wheat (Hard Red)

Hard Red is a popular variety of wheat grown around the world. The wheat grows when temperatures are above [0&deg;C](http://msuextension.org/publications/AgandNaturalResources/MT200103AG.pdf) and below [34&deg;C](http://iopscience.iop.org/article/10.1088/1748-9326/8/3/034016). Within the temperature range, an AGDD of [1665](http://msuextension.org/publications/AgandNaturalResources/MT200103AG.pdf) is required for the wheat to develop to maturity.

#### 2090 - 2098

![Wheat 2090](examples/wheat_hard_red_2090_001.png)

See [examples/wheat/](examples/wheat/) for full-year animations.

### Corn

Corn has a base temperature of [10&deg;C](https://ndawn.ndsu.nodak.edu/help-corn-growing-degree-days.html), a maximum critical temperature of about [35&deg;C](https://www.sciencedirect.com/science/article/pii/S2212094715300116), and strains differ in AGDD to reach maturity (https://en.wikipedia.org/wiki/Growing_degree-day).

#### 2090 - 2098

##### AGDD 2700 Strain

![Corn 2090](examples/corn_2700_2090_001.png)

See [examples/corn/2700](examples/corn/2700/) for full-year animations. This corn strain grows nearly nowhere. Maybe it's poor input values. Or maybe this strain will struggle in the future. Other strains grow at lower AGDD and could be better suited.

##### AGDD 800 Strain

![Corn 2090](examples/corn_800_2090_001.png)

See [examples/corn/800](examples/corn/800/) for more animations. Still processing some years.

### Upland Rice

Upland rice doesn't need to grow in paddy fields; it has a base temperature of [8.2&deg;C](https://www.sciencedirect.com/science/article/pii/S0378377417303906), maximum critical temperature of about [35&deg;C](https://books.google.ca/books?id=wS-teh0I5d0C&lpg=PP2&ots=VCWFn0Zk5N&dq=yoshida%201978%20upland%20rice&lr&pg=PP1#v=onepage&q&f=false), and requires an AGDD of around [2100](https://www.sciencedirect.com/science/article/pii/S0378377417303906) to reach maturity. 

#### 2090 - 2098

*processing*

## Notes

- There are other important factors in plant growth, like soil quality and water levels, but temperature is the most outside human control. 
- I don't include precipitation, so the assumption is that the crops will have proper irrigation. Future plans could look for like monsoons or adequate rainfall for growth.
- Predictions are made for land and sea. Maybe one day we grow crops on barges, but until then, it would be nice to remove sea grid cells.

## Setting up NEX-GDDP on Ubuntu AWS Instance

The NEX datasets are in an AWS S3 bucket in the US West (Oregon) region and processing (specifically transferring data) is fastest on Oregon instances.

### Mounting NEX-GDDP 
The NEX-GDDP data is available on AWS. To mount the data on an instance, run:
```
sudo apt-get update  
sudo apt-get upgrade  

sudo apt-get install automake autotools-dev g++ git libcurl4-gnutls-dev libfuse-dev libssl-dev libxml2-dev make pkg-config  

git clone https://github.com/s3fs-fuse/s3fs-fuse.git  
cd s3fs-fuse  
./autogen.sh  
./configure  
make  
sudo make install  

sudo sed -i -e 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf 

mkdir /home/ubuntu/nex-gddp 
sudo s3fs -o allow_other,default_acl='public_read',public_bucket=1,uid=1000,gid=1000,umask=722 nasanex:/NEX-GDDP /home/ubuntu/nex-gddp/
```

### Julia
- run ```sudo apt-get install hdf5-tools```
- download and install [Julia](https://julialang.org/)
- add packages: JLD, NetCDF