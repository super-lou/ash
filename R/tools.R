# \\\
# Copyright 2021-2022 Louis Héraut*1,
#                     Éric Sauquet*2,
#                     Valentin Mansanarez
#
# *1   INRAE, France
#      louis.heraut@inrae.fr
# *2   INRAE, France
#      eric.sauquet@inrae.fr
#
# This file is part of ash R toolbox.
#
# Ash R toolbox is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Ash R toolbox is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ash R toolbox.
# If not, see <https://www.gnu.org/licenses/>.
# ///
#
#
# R/plotting/tools.R


## 1. COLOR MANAGEMENT
### 1.1. Color on colorbar ___________________________________________
#' @title Compute color bin
#' @export
compute_colorBin = function (min, max, Palette, colorStep=256,
                             reverse=FALSE) {

    # Gets the number of discrete colors in the palette
    nSample = length(Palette)

    if (reverse) {
        Palette = rev(Palette)
    }
    # Recreates a continuous color palette
    PaletteColors = colorRampPalette(Palette)(colorStep)

    # Computes the absolute max
    maxAbs = max(abs(max), abs(min))

    bin = seq(-maxAbs, maxAbs, length.out=colorStep-1)
    upBin = c(bin, Inf)
    lowBin = c(-Inf, bin)

    res = list(Palette=PaletteColors, bin=bin, upBin=upBin, lowBin=lowBin)
    return (res)
}

#' @title Compute color
#' @export
compute_color = function (value, min, max, Palette, colorStep=256, reverse=FALSE) {

    # If the value is a NA return NA color
    if (is.na(value)) {
        return (NA)
    }
    
    res = compute_colorBin(min=min, max=max, Palette=Palette,
                           colorStep=colorStep, reverse=reverse)
    upBin = res$upBin
    lowBin = res$lowBin
    PaletteColors = res$Palette

    if (value > 0) {
        id = which(value <= upBin & value > lowBin)
    } else {
        id = which(value <= upBin & value > lowBin)
    }
    color = PaletteColors[id]
    return(color)
}

# compute_color(-51, -50, 40, Palette, colorStep=10)

#' @title Get color
#' @export
get_color = function (value, min, max, Palette, colorStep=256, reverse=FALSE, noneColor='black') {
    
    color = sapply(value, compute_color,
                   min=min,
                   max=max,
                   Palette=Palette,
                   colorStep=colorStep,
                   reverse=reverse)
    
    color[is.na(color)] = noneColor    
    return(color)
}


### 1.3. Palette tester ______________________________________________
# Allows to display the current personal palette
#' @title Palette tester
#' @export
palette_tester = function (Palette, colorStep=256) {

    outdir = 'palette'
    if (!(file.exists(outdir))) {
        dir.create(outdir)
    }

    # An arbitrary x vector
    X = 1:colorStep
    # All the same arbitrary y position to create a colorbar
    Y = rep(0, times=colorStep)

    # Recreates a continuous color palette
    Palette = colorRampPalette(Palette)(colorStep)

    # Open a void plot
    p = ggplot() + theme_void()

    for (x in X) {
        # Plot the palette
        p = p +
            annotate("segment",
                     x=x, xend=x,
                     y=0, yend=1,
                     color=Palette[x], size=1)
    }

    p = p +
        scale_x_continuous(limits=c(0, colorStep),
                           expand=c(0, 0)) +
        
        scale_y_continuous(limits=c(0, 1),
                           expand=c(0, 0))

    # Saves the plot
    outname = deparse(substitute(Palette))
    
    ggsave(plot=p,
           path=outdir,
           filename=paste(outname, '.pdf', sep=''),
           width=10, height=10, units='cm', dpi=100)

    ggsave(plot=p,
           path=outdir,
           filename=paste(outname, '.png', sep=''),
           width=10, height=10, units='cm', dpi=300)
}


#' @title Get palette
#' @export
get_palette = function (Palette, colorStep=256) {
    
    # Gets the number of discrete colors in the palette
    nSample = length(Palette)
    # Recreates a continuous color palette
    Palette = colorRampPalette(Palette)(colorStep)

    return (Palette)
}


## 2. PERSONAL PLOT __________________________________________________
### 2.1. Circle ______________________________________________________
# Allow to draw circle in ggplot2 with a radius and a center position
#' @title Circle
#' @export
gg_circle = function(r, xc, yc, color="black", fill=NA, ...) {
    x = xc + r*cos(seq(0, pi, length.out=100))
    ymax = yc + r*sin(seq(0, pi, length.out=100))
    ymin = yc + r*sin(seq(0, -pi, length.out=100))
    annotate("ribbon", x=x, ymin=ymin, ymax=ymax, color=color,
             fill=fill, ...)
}

### 2.2. Merge _______________________________________________________
#' @title Merge
#' @export
merge_panel = function (add, to, widths=NULL, heights=NULL) {
    # Plot the graph as the layout
    plot = grid.arrange(grobs=list(add, to),
                        heights=heights, widths=widths)
    return (plot)
}


## 3. NUMBER MANAGEMENT ______________________________________________
### 3.1. Number formatting ___________________________________________
# Returns the power of ten of the scientific expression of a value
#' @title Number formatting
#' @export
get_power = function (value) {

    if (length(value) > 1) {
        power = unlist(as.list(sapply(value, get_power),
                               recursive=TRUE,
                               use.names=FALSE))
    } else {
        if (!is.na(value)) {
            # Do not care about the sign
            value = abs(value)
            
            # If the value is greater than one
            if (value >= 1) {
                # The magnitude is the number of character of integer part
                # of the value minus one
                power = nchar(as.character(as.integer(value))) - 1
                # If value is zero
            } else if (value == 0) {
                # The power is zero
                power = 0
                # If the value is less than one
            } else {
                # Extract the decimal part
                dec = gsub('0.', '', as.character(value), fixed=TRUE)
                # Number of decimal with zero
                ndec = nchar(dec)
                # Number of decimal without zero
                nnum = nchar(as.character(as.numeric(dec)))
                # Compute the power of ten associated
                power = -(ndec - nnum + 1)
            }
        } else {
            power = NA
        }
    }
    return (power)
}

### 3.2. Pourcentage of variable _____________________________________
# Returns the value corresponding of a certain percentage of a
# data serie
#' @title Pourcentage of variable
#' @export
gpct = function (pct, L, min_lim=NULL, shift=FALSE) {

    # If no reference for the serie is given
    if (is.null(min_lim)) {
        # The minimum of the serie is computed
        minL = min(L, na.rm=TRUE)
    # If a reference is specified
    } else {
        # The reference is the minimum
        minL = min_lim
    }

    # Gets the max
    maxL = max(L, na.rm=TRUE)
    # And the span
    spanL = maxL - minL
    # Computes the value corresponding to the percentage
    xL = pct/100 * as.numeric(spanL)

    # If the value needs to be shift by its reference
    if (shift) {
        xL = xL + minL
    }
    return (xL)
}

### 3.3. Add months __________________________________________________
#' @title Add months
#' @export
add_months = function (date, n) {
    new_date = seq(date, by = paste (n, "months"), length = 2)[2]
    return (new_date)
}


## 4. LOADING ________________________________________________________
### 4.1. Shapefile loading ___________________________________________
#' @title Shapefiles loading
#' @description  Generates a list of shapefiles to draw a hydrological
#' map of the France
#' @param resources_path Path to the resources directory.
#' @param fr_shpdir Directory you want to use in ash\\resources_path\\
#' to get the France shapefile.
#' @param fr_shpname Name of the France shapefile.
#' @param bs_shpdir Directory you want to use in ash\\resources_path\\
#' to get the hydrological basin shapefile.
#' @param bs_shpname Name of the hydrological basin shapefile.
#' @param sbs_shpdir Directory you want to use in
#' ash\\resources_path\\ to get the hydrological sub-basin shapefile.
#' @param sbs_shpname Name of the hydrological sub-basin shapefile.
#' @param rv_shpdir Directory you want to use in ash\\resources_path\\
#' to get the hydrological network shapefile.
#' @param rv_shpname  Name of the hydrological network shapefile.
#' @param show_river Boolean to indicate if the shapefile of the
#' hydrological network will be charge because it is a heavy one and
#' that it slows down the entire process (default : TRUE)
#' @return A list of shapefiles converted as tibbles that can be plot
#' with 'geom_polygon' or 'geom_path'.
#' @export
load_shapefile = function (resources_path, df_meta,
                           fr_shpdir, fr_shpname,
                           bs_shpdir, bs_shpname,
                           sbs_shpdir, sbs_shpname,
                           cbs_shpdir, cbs_shpname, cbs_coord,
                           rv_shpdir, rv_shpname,
                           river_selection=c('all')) {

    Code = rle(df_data$Code)$value
    
    # Path for shapefile
    fr_shppath = file.path(resources_path, fr_shpdir, fr_shpname)
    bs_shppath = file.path(resources_path, bs_shpdir, bs_shpname)
    sbs_shppath = file.path(resources_path, sbs_shpdir, sbs_shpname)
    cbs_shppath = file.path(resources_path, cbs_shpdir, cbs_shpname)
    rv_shppath = file.path(resources_path, rv_shpdir, rv_shpname)
    
    # France
    fr_spdf = rgdal::readOGR(dsn=fr_shppath, verbose=FALSE)    
    sp::proj4string(fr_spdf) = sp::CRS("+proj=longlat +ellps=WGS84")
    # Transformation in Lambert93
    france = spTransform(fr_spdf, sp::CRS("+init=epsg:2154"))
    df_france = tibble(ggplot2::fortify(france))

    # Hydrological basin
    basin = rgdal::readOGR(dsn=bs_shppath, verbose=FALSE)
    df_basin = tibble(ggplot2::fortify(basin))

    # Hydrological sub-basin
    subBasin = rgdal::readOGR(dsn=sbs_shppath, verbose=FALSE)
    df_subBasin = tibble(ggplot2::fortify(subBasin))

    df_codeBasin = tibble()
    CodeOk = c()
    nShp = length(cbs_shppath)
    # Hydrological stations basins
    for (i in 1:nShp) {
        codeBasin = rgdal::readOGR(dsn=cbs_shppath[i], verbose=FALSE)
        shpCode = as.character(codeBasin@data$code)
        df_tmp = tibble(ggplot2::fortify(codeBasin))
        groupSample = rle(as.character(df_tmp$group))$values
        df_tmp$code = shpCode[match(df_tmp$group, groupSample)]
        df_tmp = df_tmp[df_tmp$code %in% Code &
                        !(df_tmp$code %in% CodeOk),]
        CodeOk = c(CodeOk, shpCode[!(shpCode %in% CodeOk)])

        if (cbs_coord[i] == "L2") {
            crs_rgf93 = sf::st_crs(2154)
            crs_l2 = sf::st_crs(27572)
            sf_loca = sf::st_as_sf(df_tmp[c("long", "lat")],
                                   coords=c("long", "lat"))
            sf::st_crs(sf_loca) = crs_l2
            sf_loca = sf::st_transform(sf_loca, crs_rgf93)
            sf_loca = sf::st_coordinates(sf_loca$geometry)
            df_tmp$long = sf_loca[, 1]
            df_tmp$lat = sf_loca[, 2]
        }
        df_codeBasin = bind_rows(df_codeBasin, df_tmp)
    }
    names(df_codeBasin)[names(df_codeBasin) == "code"] = "Code"
    df_codeBasin = df_codeBasin[order(df_codeBasin$Code),]
    
    # If the river shapefile needs to be load
    if (!("none" %in% river_selection)) {
        # Hydrographic network
        river = rgdal::readOGR(dsn=rv_shppath, verbose=FALSE) ### trop long ###
        if ('all' %in% river_selection) {
            river = river[river$Classe == 1,]
        } else {
            river = river[grepl(paste(river_selection, collapse='|'),
                                river$NomEntiteH),]
        }
        df_river = tibble(ggplot2::fortify(river))
    } else {
        df_river = NULL   
    }
    return (list(france=df_france,
                 basin=df_basin,
                 subBasin=df_subBasin,
                 codeBasin=df_codeBasin,
                 river=df_river))
}

### 4.2. Logo loading ________________________________________________
#' @title Logo loading
#' @export
load_logo = function (resources_path, logo_dir, PRlogo_file, AEAGlogo_file,
                      INRAElogo_file, FRlogo_file, logo_to_show) {

    logo_path = c()
    if ('PR' %in% logo_to_show) {
        path = file.path(resources_path, logo_dir, PRlogo_file)
        logo_path = c(logo_path, path)
        names(logo_path)[length(logo_path)] = 'PR'
    }
    if ('FR' %in% logo_to_show) {
        path = file.path(resources_path, logo_dir, FRlogo_file)
        logo_path = c(logo_path, path)
        names(logo_path)[length(logo_path)] = 'FR'
    }
    if ('INRAE' %in% logo_to_show) {
        path = file.path(resources_path, logo_dir, INRAElogo_file)
        logo_path = c(logo_path, path)
        names(logo_path)[length(logo_path)] = 'INRAE'
    }
    if ('AEAG' %in% logo_to_show) {
        path = file.path(resources_path, logo_dir, AEAGlogo_file)
        logo_path = c(logo_path, path)
        names(logo_path)[length(logo_path)] = 'AEAG'
    }
    
    return (logo_path)
}



    
