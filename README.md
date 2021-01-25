# Open Postcode Polygons

Open Postcode Polygons is an attempt to make an Open Data version of the UK postcode system. If you need postcode points, the official [code point open](https://www.ordnancesurvey.co.uk/business-government/products/code-point-open) is better.

## Why is this needed

Although Postcode points are [published](https://www.ordnancesurvey.co.uk/business-government/products/code-point-open) as open data, the polygons showing the exact boundaries of each Postcode area are not.  This is a little bonkers considering how important they are to our address system, and that they are hardly a secret. However, as the Postcode system is owned by Royal Mail, which is now a private company, it is unlikely that the Postcode polygons will be published anytime soon.

## What does this repo do?

This repo attempts to recreate the postcode polygons using only free open data, thus negating the need to purchase the official dataset. This is achieved through multiple datasets and some clever coding.

Some people have already attempted this, but the results have not been very good. This repo enhances their methods using the following techniques.

1. Use Code Point Open points to get the approximate location of the postcode area
2. Use extra data from open source projects. These provide alternative locations and thus provide an estimate of the extent of the postcode area. Sources include:
  * [New Popular Edition Maps](http://www.npemap.org.uk/)
  * [Free the postcode](http://www.freethepostcode.org/)
  * [Postbox Locator](https://postboxes.dracos.co.uk/)
  * [OpenStreetMap](https://www.openstreetmap.org/#map=6/54.910/-3.432)

2. Use the fact that the original [Output Areas](https://www.ons.gov.uk/census/2001censusandearlier/dataandproducts/outputgeography/outputareas) for the 2001 Census were partially based on postcode areas.
3. Within each Output Area construct Voronoi polygons to approximate postcode areas.

These techniques are not perfect, but they produce reasonably good results in many areas.

**Example: Open Postcodes (blue), real postcode areas (red)**
<img src='postcode.png'/> 

## How can I contribute?

If you have open source postcode data to share, please open an [issue](https://github.com/ITSLeeds/OpenPostcodes/issues).

If you know just a few postcodes then tag them in the OpenStreetMap, the best way to do this is to add the `postal_code` tag to the buildings. The more buildings that are correctly tagged, the more accurate the postcode areas become.



## Legal Stuff

### OA Boundaries

Contains National Statistics data © Crown copyright and database right [2020]
Contains OS data © Crown copyright [and database right] (2020)
    
Office for National Statistics (2001). 2001 Census: boundary data (England and Wales) [data collection].
UK Data Service. SN:5819 UKBORDERS: Digitised Boundary Data, 1840- and Postcode Directories, 1980-.
http://discover.ukdataservice.ac.uk/catalogue/?sn=5819&type=Data%20catalogue,
Retrieved from http://census.ukdataservice.ac.uk/get-data/boundary-data.aspx.


### Postcode Points

ORDNANCE SURVEY DATA LICENCE

Your use of data is subject to terms at www.ordnancesurvey.co.uk/opendata/licence.

Contains Ordnance Survey data © Crown copyright and database right 2020.

Contains Royal Mail data © Royal Mail copyright and database right 2020.
Contains National Statistics data © Crown copyright and database right 2020.

February 2020
Contains public sector information licensed under the Open Government Licence v3.

### OpenStreetMap




### New Popular Edition Maps



### Free the postcode



### Postbox Locator

