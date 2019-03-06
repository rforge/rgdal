/* Copyright (c) 2019 Roger Bivand */


#include <R.h>
#include <Rdefines.h>
#include "rgdal.h"
#ifdef ACCEPT_USE_OF_DEPRECATED_PROJ_API_H // kludge for 6 only
#include <proj.h>

#ifdef __cplusplus
extern "C" {
#endif



SEXP RGDAL_projInfo(SEXP type) {
    SEXP ans=NULL;
    SEXP ansnames;
    int n=0, pc=0;


    if (INTEGER_POINTER(type)[0] == 0) {
        PROTECT(ans = NEW_LIST(2)); pc++;
        PROTECT(ansnames = NEW_CHARACTER(2)); pc++;
        SET_STRING_ELT(ansnames, 0, COPY_TO_USER_STRING("name"));
        SET_STRING_ELT(ansnames, 1, COPY_TO_USER_STRING("description"));
        setAttrib(ans, R_NamesSymbol, ansnames);

        const struct PJ_LIST *lp;
        for (lp = proj_list_operations() ; lp->id ; ++lp) {
            if( strcmp(lp->id,"latlong") == 0
                || strcmp(lp->id,"longlat") == 0
                || strcmp(lp->id,"geocent") == 0 )
            continue;
            n++;
        }
        SET_VECTOR_ELT(ans, 0, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 1, NEW_CHARACTER(n));
        n=0;
        for (lp = proj_list_operations() ; lp->id ; ++lp) {
            if( strcmp(lp->id,"latlong") == 0
                || strcmp(lp->id,"longlat") == 0
                || strcmp(lp->id,"geocent") == 0 )
            continue;
            SET_STRING_ELT(VECTOR_ELT(ans, 0), n, 
		COPY_TO_USER_STRING(lp->id));

            SET_STRING_ELT(VECTOR_ELT(ans, 1), n, 
		COPY_TO_USER_STRING(*lp->descr));
            n++;
        }
    } else if (INTEGER_POINTER(type)[0] == 1) {
        PROTECT(ans = NEW_LIST(4)); pc++;
        PROTECT(ansnames = NEW_CHARACTER(4)); pc++;
        SET_STRING_ELT(ansnames, 0, COPY_TO_USER_STRING("name"));
        SET_STRING_ELT(ansnames, 1, COPY_TO_USER_STRING("major"));
        SET_STRING_ELT(ansnames, 2, COPY_TO_USER_STRING("ell"));
        SET_STRING_ELT(ansnames, 3, COPY_TO_USER_STRING("description"));
        setAttrib(ans, R_NamesSymbol, ansnames);

        const struct PJ_ELLPS *le;
        for (le = proj_list_ellps(); le->id ; ++le) n++;
        SET_VECTOR_ELT(ans, 0, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 1, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 2, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 3, NEW_CHARACTER(n));
        n=0;
        for (le = proj_list_ellps(); le->id ; ++le) {
            SET_STRING_ELT(VECTOR_ELT(ans, 0), n, 
		COPY_TO_USER_STRING(le->id));
            SET_STRING_ELT(VECTOR_ELT(ans, 1), n, 
		COPY_TO_USER_STRING(le->major));
            SET_STRING_ELT(VECTOR_ELT(ans, 2), n, 
		COPY_TO_USER_STRING(le->ell));
            SET_STRING_ELT(VECTOR_ELT(ans, 3), n, 
		COPY_TO_USER_STRING(le->name));
            n++;
        }
    } else if (INTEGER_POINTER(type)[0] == 2) {
        return(R_NilValue);
/*        PROTECT(ans = NEW_LIST(4)); pc++;
        PROTECT(ansnames = NEW_CHARACTER(4)); pc++;
        SET_STRING_ELT(ansnames, 0, COPY_TO_USER_STRING("name"));
        SET_STRING_ELT(ansnames, 1, COPY_TO_USER_STRING("ellipse"));
        SET_STRING_ELT(ansnames, 2, COPY_TO_USER_STRING("definition"));
        SET_STRING_ELT(ansnames, 3, COPY_TO_USER_STRING("description"));
        setAttrib(ans, R_NamesSymbol, ansnames);

        const struct PJ_DATUMS *ld;
        for (ld = pj_get_datums_ref(); ld->id ; ++ld) n++;
        SET_VECTOR_ELT(ans, 0, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 1, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 2, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 3, NEW_CHARACTER(n));
        n=0;
        for (ld = pj_get_datums_ref(); ld->id ; ++ld) {
            SET_STRING_ELT(VECTOR_ELT(ans, 0), n, 
		COPY_TO_USER_STRING(ld->id));
            SET_STRING_ELT(VECTOR_ELT(ans, 1), n, 
		COPY_TO_USER_STRING(ld->ellipse_id));
            SET_STRING_ELT(VECTOR_ELT(ans, 2), n, 
		COPY_TO_USER_STRING(ld->defn));
            SET_STRING_ELT(VECTOR_ELT(ans, 3), n, 
		COPY_TO_USER_STRING(ld->comments));
            n++;
        }*/

    } else if (INTEGER_POINTER(type)[0] == 3) {
        PROTECT(ans = NEW_LIST(3)); pc++;
        PROTECT(ansnames = NEW_CHARACTER(3)); pc++;
        SET_STRING_ELT(ansnames, 0, COPY_TO_USER_STRING("id"));
        SET_STRING_ELT(ansnames, 1, COPY_TO_USER_STRING("to_meter"));
        SET_STRING_ELT(ansnames, 2, COPY_TO_USER_STRING("name"));
        setAttrib(ans, R_NamesSymbol, ansnames);

        const struct PJ_UNITS *lu;
        for (lu = proj_list_units(); lu->id ; ++lu) n++;
        SET_VECTOR_ELT(ans, 0, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 1, NEW_CHARACTER(n));
        SET_VECTOR_ELT(ans, 2, NEW_CHARACTER(n));
        n=0;
        for (lu = proj_list_units(); lu->id ; ++lu) {
            SET_STRING_ELT(VECTOR_ELT(ans, 0), n, 
		COPY_TO_USER_STRING(lu->id));
            SET_STRING_ELT(VECTOR_ELT(ans, 1), n, 
		COPY_TO_USER_STRING(lu->to_meter));
            SET_STRING_ELT(VECTOR_ELT(ans, 2), n, 
		COPY_TO_USER_STRING(lu->name));
            n++;
        }
    } else error("no such type");
    
    UNPROTECT(pc);
    return(ans);
}
#endif


#ifdef __cplusplus
}
#endif

