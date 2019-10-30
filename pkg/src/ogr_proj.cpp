/* Copyright (c) 2006 Roger Bivand
* Function using C API and based on GPJ_grass_to_wkt from GRASS gproj
* library by Paul Kelly and Frank Warmerdam */


#include "ogrsf_frmts.h"
#include <ogr_spatialref.h>

// R headers moved outside extern "C" 070808 RSB re. note from BDR
// #ifdef __cplusplus
// extern "C" {
// #endif
#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>
#include "rgdal.h"

#ifdef __cplusplus
extern "C" {
#endif


SEXP P6_SRID_show(SEXP inSRID, SEXP format, SEXP multiline, SEXP in_format,
    SEXP epsg, SEXP out_format) {

#if GDAL_VERSION_MAJOR >= 3

    OGRSpatialReference hSRS = (OGRSpatialReference) NULL;
    char *pszSRS = NULL;
    SEXP ans;
    char **papszOptions = NULL;

    if (INTEGER_POINTER(in_format)[0] == 1L) {
        installErrorHandler();
        if (hSRS.importFromProj4((const char *) CHAR(STRING_ELT(inSRID, 0))) != OGRERR_NONE) {
            uninstallErrorHandlerAndTriggerError();
	    error("Can't parse PROJ.4-style parameter string");
        }
        uninstallErrorHandlerAndTriggerError();
    } else if (INTEGER_POINTER(in_format)[0] == 2L) {
        installErrorHandler();
        if (hSRS.importFromURN((const char *) CHAR(STRING_ELT(inSRID, 0))) != OGRERR_NONE) {
            uninstallErrorHandlerAndTriggerError();
	    error("Can't parse URN-style parameter string");
        }
        uninstallErrorHandlerAndTriggerError();
    } else if (INTEGER_POINTER(in_format)[0] == 3L) {
        installErrorHandler();
        if (hSRS.importFromWkt((const char *) CHAR(STRING_ELT(inSRID, 0))) != OGRERR_NONE) {
            uninstallErrorHandlerAndTriggerError();
	    error("Can't parse WKT-style parameter string");
        }
        uninstallErrorHandlerAndTriggerError();
    } else if (INTEGER_POINTER(in_format)[0] == 4L) {
        installErrorHandler();
        if (hSRS.importFromEPSG(INTEGER_POINTER(epsg)[0]) != OGRERR_NONE) {
            uninstallErrorHandlerAndTriggerError();
	    error("Can't parse EPSG-style code");
        }
        uninstallErrorHandlerAndTriggerError();
    }

    PROTECT(ans=NEW_CHARACTER(1));

    if (INTEGER_POINTER(out_format)[0] == 1L) {
        installErrorHandler();
        papszOptions = CSLAddString(papszOptions, CHAR(STRING_ELT(multiline, 0)));
        papszOptions = CSLAddString(papszOptions, CHAR(STRING_ELT(format, 0)));
        uninstallErrorHandlerAndTriggerError();

        installErrorHandler();
        
        if (hSRS.exportToWkt(&pszSRS, papszOptions) != OGRERR_NONE) {
            uninstallErrorHandlerAndTriggerError();
	    error("Can't express as WKT");
        }
        uninstallErrorHandlerAndTriggerError();
        SET_STRING_ELT(ans, 0, COPY_TO_USER_STRING(pszSRS));
    } else if (INTEGER_POINTER(out_format)[0] == 2L) {
        installErrorHandler();
        if (hSRS.exportToProj4(&pszSRS) != OGRERR_NONE) {
            SET_STRING_ELT(ans, 0, NA_STRING);
	} else {
            SET_STRING_ELT(ans, 0, COPY_TO_USER_STRING(pszSRS));
        }
        uninstallErrorHandlerAndTriggerError();
    } else {
        error("unknown output format");
    }

    CPLFree(pszSRS);

    UNPROTECT(1);

    return(ans);
#else
    return(R_NilValue);
#endif

}


SEXP p4s_to_wkt(SEXP p4s, SEXP esri) {

    OGRSpatialReference hSRS = (OGRSpatialReference) NULL;
    char *pszSRS_WKT = NULL;
    SEXP ans;

    installErrorHandler();
    if (hSRS.importFromProj4(CHAR(STRING_ELT(p4s, 0))) != OGRERR_NONE) {
        uninstallErrorHandlerAndTriggerError();
	error("Can't parse PROJ.4-style parameter string");
    }
    uninstallErrorHandlerAndTriggerError();
    installErrorHandler();
    if (INTEGER_POINTER(esri)[0] == 1) hSRS.morphToESRI();
    hSRS.exportToWkt(&pszSRS_WKT);//FIXME VG
    uninstallErrorHandlerAndTriggerError();

    PROTECT(ans=NEW_CHARACTER(1));
    SET_STRING_ELT(ans, 0, COPY_TO_USER_STRING(pszSRS_WKT));

    UNPROTECT(1);

    return(ans);
}

SEXP wkt_to_p4s(SEXP wkt, SEXP esri) {

    OGRSpatialReference hSRS = (OGRSpatialReference) NULL;
    char *pszSRS_P4 = NULL;
    char **ppszInput = NULL;
    SEXP ans;
    ppszInput = CSLAddString(ppszInput, CHAR(STRING_ELT(wkt, 0)));//FIXME VG

    installErrorHandler();
#if GDAL_VERSION_MAJOR == 1 || ( GDAL_VERSION_MAJOR == 2 && GDAL_VERSION_MINOR <= 2 ) // thanks to Even Roualt https://github.com/OSGeo/gdal/issues/681
//#if GDAL_VERSION_MAJOR <= 2 && GDAL_VERSION_MINOR <= 2
    if (hSRS.importFromWkt(ppszInput) != OGRERR_NONE) 
#else
    if (hSRS.importFromWkt((const char **) ppszInput) != OGRERR_NONE) 
#endif
    {
        uninstallErrorHandlerAndTriggerError();
	error("Can't parse WKT-style parameter string");
    }
    uninstallErrorHandlerAndTriggerError();

    installErrorHandler();
    if (INTEGER_POINTER(esri)[0] == 1) hSRS.morphFromESRI();
    hSRS.exportToProj4(&pszSRS_P4);//FIXME VG
    uninstallErrorHandlerAndTriggerError();

    PROTECT(ans=NEW_CHARACTER(1));
    SET_STRING_ELT(ans, 0, COPY_TO_USER_STRING(pszSRS_P4));

    UNPROTECT(1);

    return(ans);
}

SEXP ogrAutoIdentifyEPSG(SEXP p4s) {

    OGRSpatialReference hSRS = (OGRSpatialReference) NULL;
    OGRErr thisOGRErr;
    SEXP ans;

    installErrorHandler();
    if (hSRS.importFromProj4(CHAR(STRING_ELT(p4s, 0))) != OGRERR_NONE) {
        uninstallErrorHandlerAndTriggerError();
	error("Can't parse PROJ.4-style parameter string");
    }
    uninstallErrorHandlerAndTriggerError();
    PROTECT(ans=NEW_CHARACTER(1));

    installErrorHandler();
    thisOGRErr = hSRS.AutoIdentifyEPSG();
    uninstallErrorHandlerAndTriggerError();

    if (thisOGRErr == OGRERR_NONE) {
        installErrorHandler();
        SET_STRING_ELT(ans, 0,
            COPY_TO_USER_STRING(hSRS.GetAuthorityCode(NULL)));
        uninstallErrorHandlerAndTriggerError();
    } else if (thisOGRErr == OGRERR_UNSUPPORTED_SRS) {
        SET_STRING_ELT(ans, 0,
            COPY_TO_USER_STRING("OGRERR_UNSUPPORTED_SRS"));
    }

    UNPROTECT(1);

    return(ans);
}

SEXP ogrP4S(SEXP ogrsourcename, SEXP Layer, SEXP morphFromESRI, SEXP dumpSRS) {

#ifdef GDALV2
//    GDALDriver *poDriver;
    GDALDataset *poDS;
#else
    OGRSFDriver *poDriver;
    OGRDataSource *poDS;
#endif
    OGRLayer *poLayer;

    OGRSpatialReference *hSRS = NULL;
    char *pszProj4 = NULL;
    SEXP ans, Datum, ToWGS84, OSRProjVersion;
    int i, pc=0;
    int pnMajor, pnMinor, pnPatch;
    const char *datum, *towgs84;

    installErrorHandler();
#ifdef GDALV2
    poDS=(GDALDataset*) GDALOpenEx(CHAR(STRING_ELT(ogrsourcename, 0)), GDAL_OF_VECTOR, NULL, NULL, NULL);
#else
    poDS=OGRSFDriverRegistrar::Open(CHAR(STRING_ELT(ogrsourcename, 0)), 
	FALSE, &poDriver);
#endif
    uninstallErrorHandlerAndTriggerError();

    if(poDS==NULL){
      error("Cannot open file");
    }
    installErrorHandler();
    poLayer = poDS->GetLayerByName(CHAR(STRING_ELT(Layer, 0)));
    uninstallErrorHandlerAndTriggerError();

    if(poLayer == NULL){
      error("Cannot open layer");
    }

    PROTECT(ans=NEW_CHARACTER(1)); pc++;

    installErrorHandler();
    hSRS = poLayer->GetSpatialRef();
    uninstallErrorHandlerAndTriggerError();

    installErrorHandler();
    if (LOGICAL_POINTER(dumpSRS)[0]) {
        hSRS->dumpReadable();
    }
    uninstallErrorHandlerAndTriggerError();


#if GDAL_VERSION_MAJOR >= 3
    installErrorHandler();
    OSRGetPROJVersion(&pnMajor, &pnMinor, &pnPatch);
    uninstallErrorHandlerAndTriggerError();
    PROTECT(OSRProjVersion = NEW_INTEGER(3)); pc++;
    INTEGER_POINTER(OSRProjVersion)[0] = pnMajor;
    INTEGER_POINTER(OSRProjVersion)[1] = pnMinor;
    INTEGER_POINTER(OSRProjVersion)[2] = pnPatch;
#endif

    installErrorHandler();
    datum = hSRS->GetAttrValue("DATUM");
    uninstallErrorHandlerAndTriggerError();
    PROTECT(Datum = NEW_CHARACTER(1)); pc++;
    if (datum != NULL) SET_STRING_ELT(Datum, 0, COPY_TO_USER_STRING(datum));

    PROTECT(ToWGS84 = NEW_CHARACTER(7)); pc++;
    installErrorHandler();
    for (i=0; i<7; i++) {
        towgs84 = hSRS->GetAttrValue("TOWGS84", i);
        if (towgs84 != NULL) SET_STRING_ELT(ToWGS84, i,
            COPY_TO_USER_STRING(towgs84));
    }
    uninstallErrorHandlerAndTriggerError();


    if (hSRS != NULL) {
        installErrorHandler();
	if (LOGICAL_POINTER(morphFromESRI)[0]) hSRS->morphFromESRI();
        if (hSRS->exportToProj4(&pszProj4) != OGRERR_NONE) {
            SET_STRING_ELT(ans, 0, NA_STRING);
	} else {
            SET_STRING_ELT(ans, 0, COPY_TO_USER_STRING(pszProj4));
            CPLFree(pszProj4);
	}
        uninstallErrorHandlerAndTriggerError();
      } else SET_STRING_ELT(ans, 0, NA_STRING);

    installErrorHandler();
    delete poDS;
    uninstallErrorHandlerAndTriggerError();

    setAttrib(ans, install("towgs84"), ToWGS84);
    setAttrib(ans, install("datum"), Datum);
#if GDAL_VERSION_MAJOR >= 3
    setAttrib(ans, install("OSRProjVersion"), OSRProjVersion);
#endif

    UNPROTECT(pc);
    return(ans);
}
#ifdef __cplusplus
}
#endif


