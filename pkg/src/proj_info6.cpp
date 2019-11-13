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

// unname(sapply(o[[2]], function(x) gsub(" ", " +", paste0("+", x))))

SEXP list_coordinate_ops(SEXP source, SEXP target, SEXP area_of_interest, SEXP strict_containment, SEXP vis_order) {

    PJ_CONTEXT *ctx = proj_context_create();
    PJ_OPERATION_FACTORY_CONTEXT* operation_factory_context = NULL;
    PJ_OBJ_LIST *pj_operations = NULL;
    PJ *source_crs, *target_crs;
    PJ* pj_transform = NULL;
    SEXP ans, input;
    int num_operations, i, j, is_instantiable, is_ballpark, grid_count;
    int pc=0;
    double accuracy;
    int grid_OK, out_direct_download, out_open_license, out_available;
    const char *out_short_name, *out_full_name, *out_package_name, *out_url;
    PJ_PROJ_INFO pjinfo;

    source_crs = proj_create(ctx, CHAR(STRING_ELT(source, 0)));

    if (source_crs == NULL) {
        proj_context_destroy(ctx);
        error("source crs not created");
    }
    
    target_crs = proj_create(ctx, CHAR(STRING_ELT(target, 0)));

    if (target_crs == NULL) {
        proj_destroy(source_crs);
        proj_context_destroy(ctx);
        error("target crs not created");
    }

    operation_factory_context = proj_create_operation_factory_context(ctx,
        NULL);
    if (operation_factory_context == NULL) {
        proj_destroy(source_crs); proj_destroy(target_crs);
        proj_context_destroy(ctx);
        error("operation factory context not created");
    }

    if (!ISNA(NUMERIC_POINTER(area_of_interest)[0])) {
        proj_operation_factory_context_set_area_of_interest(
            ctx, operation_factory_context,
            NUMERIC_POINTER(area_of_interest)[0],
            NUMERIC_POINTER(area_of_interest)[1],
            NUMERIC_POINTER(area_of_interest)[2],
            NUMERIC_POINTER(area_of_interest)[3]);
    }

    if (LOGICAL_POINTER(strict_containment)[0])
        proj_operation_factory_context_set_spatial_criterion(
            ctx, operation_factory_context,
            PROJ_SPATIAL_CRITERION_STRICT_CONTAINMENT);
    else proj_operation_factory_context_set_spatial_criterion(
            ctx, operation_factory_context,
            PROJ_SPATIAL_CRITERION_PARTIAL_INTERSECTION);

    proj_operation_factory_context_set_grid_availability_use(
            ctx, operation_factory_context,
            PROJ_GRID_AVAILABILITY_USED_FOR_SORTING);

    pj_operations = proj_create_operations(ctx,
                source_crs, target_crs, operation_factory_context);
    
    if (pj_operations == NULL) {
        proj_operation_factory_context_destroy(operation_factory_context);
        proj_destroy(source_crs); proj_destroy(target_crs);
        proj_context_destroy(ctx);
        error("operations list not created");
    }

    num_operations = proj_list_get_count(pj_operations);

    if (num_operations < 1L) {
        proj_list_destroy(pj_operations);
        proj_operation_factory_context_destroy(operation_factory_context);
        proj_destroy(source_crs); proj_destroy(target_crs);
        proj_context_destroy(ctx);
        return(R_NilValue);
    }

    PROTECT(ans=NEW_LIST(7)); pc++;
    SET_VECTOR_ELT(ans, 0, NEW_CHARACTER(num_operations));
    SET_VECTOR_ELT(ans, 1, NEW_CHARACTER(num_operations));
    SET_VECTOR_ELT(ans, 2, NEW_NUMERIC(num_operations));
    SET_VECTOR_ELT(ans, 3, NEW_LOGICAL(num_operations));
    SET_VECTOR_ELT(ans, 4, NEW_LOGICAL(num_operations));
    SET_VECTOR_ELT(ans, 5, NEW_INTEGER(num_operations));
    SET_VECTOR_ELT(ans, 6, NEW_LIST(num_operations));

    PROTECT(input=NEW_LIST(5)); pc++;
    SET_VECTOR_ELT(input, 0, source);
    SET_VECTOR_ELT(input, 1, target);
    SET_VECTOR_ELT(input, 2, area_of_interest);
    SET_VECTOR_ELT(input, 3, strict_containment);
    SET_VECTOR_ELT(input, 4, vis_order);
    setAttrib(ans, install("input"), input);


    for (i=0; i<num_operations; i++) {
        pj_transform = proj_list_get(ctx, pj_operations, i);
        if (LOGICAL_POINTER(vis_order)[0])
            pj_transform = proj_normalize_for_visualization(ctx, pj_transform);
        is_instantiable = proj_coordoperation_is_instantiable(ctx,
            pj_transform);
        is_ballpark = proj_coordoperation_has_ballpark_transformation(ctx,
            pj_transform);
        accuracy = proj_coordoperation_get_accuracy(ctx,
            pj_transform);
        grid_count = proj_coordoperation_get_grid_used_count(ctx,
            pj_transform);
        pjinfo = proj_pj_info(pj_transform);
        SET_STRING_ELT(VECTOR_ELT(ans, 0), i,
            COPY_TO_USER_STRING(pjinfo.description));
        SET_STRING_ELT(VECTOR_ELT(ans, 1), i,
            COPY_TO_USER_STRING(pjinfo.definition));

        NUMERIC_POINTER(VECTOR_ELT(ans, 2))[i] = accuracy;
        LOGICAL_POINTER(VECTOR_ELT(ans, 3))[i] = is_instantiable;
        LOGICAL_POINTER(VECTOR_ELT(ans, 4))[i] = is_ballpark;
        INTEGER_POINTER(VECTOR_ELT(ans, 5))[i] = grid_count;

        if (grid_count > 0L) {
            SET_VECTOR_ELT(VECTOR_ELT(ans, 6), i, NEW_LIST(grid_count));
            for (j=0; j<grid_count; j++) {
                grid_OK = proj_coordoperation_get_grid_used(ctx, pj_transform,
                    j, &out_short_name, &out_full_name, &out_package_name,
                    &out_url, &out_direct_download, &out_open_license,
                    &out_available);
                 if (grid_OK) {
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(ans, 6), i), j,
                         NEW_LIST(7));
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 0, NEW_CHARACTER(1));
                     SET_STRING_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 0), 0,
                         COPY_TO_USER_STRING(out_short_name));
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 1, NEW_CHARACTER(1));
                     SET_STRING_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 1), 0, 
                         COPY_TO_USER_STRING(out_full_name));
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 2, NEW_CHARACTER(1));
                     SET_STRING_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 2), 0, 
                         COPY_TO_USER_STRING(out_package_name));
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 3, NEW_CHARACTER(1));
                     SET_STRING_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 3), 0, 
                         COPY_TO_USER_STRING(out_url));
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 4, NEW_LOGICAL(1));
                     LOGICAL_POINTER(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 4))[0] = 
                         out_direct_download;
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 5, NEW_LOGICAL(1));
                     LOGICAL_POINTER(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 5))[0] = 
                         out_open_license;
                     SET_VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT( ans, 6),
                         i), j), 6, NEW_LOGICAL(1));
                     LOGICAL_POINTER(VECTOR_ELT(VECTOR_ELT(VECTOR_ELT(
                         VECTOR_ELT(ans, 6), i), j), 6))[0] = 
                         out_available;

                 } 
            }
        }
    }

    proj_destroy(pj_transform);
    proj_list_destroy(pj_operations);
    proj_operation_factory_context_destroy(operation_factory_context);
    proj_destroy(source_crs); proj_destroy(target_crs);
    proj_context_destroy(ctx);

    UNPROTECT(pc);
    return(ans);

}


// blocks error messages in this context
// https://lists.osgeo.org/pipermail/proj/2019-March/008310.html
static void proj_logger(void * user_data, int level, const char * message) {}

// code borrowed from GRASS g.proj main.c adapted for PROJ6 by Markus Metz

SEXP
PROJcopyEPSG(SEXP tf) {

    SEXP ans;
    PROTECT(ans=NEW_INTEGER(1));
    INTEGER_POINTER(ans)[0] = 0;
    int i, crs_cnt;
    PROJ_CRS_INFO **proj_crs_info;
    PJ_CONTEXT *ctx = proj_context_create();
    FILE *fptf;

	
    crs_cnt = 0;
    proj_crs_info = proj_get_crs_info_list_from_database(ctx, "EPSG", NULL,
        &crs_cnt);
    if (crs_cnt < 1) {
        UNPROTECT(1);
        return(ans);
    }
    fptf = fopen(CHAR(STRING_ELT(tf, 0)), "wb");
    if (fptf == NULL) {
        UNPROTECT(1);
        return(ans);
    }
    fprintf(fptf, "\"code\",\"note\",\"prj4\",\"prj_method\"\n");

    PJ *pj;
// blocks error messages in this context
    proj_log_func(ctx, NULL, proj_logger);
    for (i = 0; i < crs_cnt; i++) {
        const char *proj_definition;

        pj = proj_create_from_database(ctx, proj_crs_info[i]->auth_name,
            proj_crs_info[i]->code, PJ_CATEGORY_CRS, 0, NULL);
        proj_definition = proj_as_proj_string(ctx, pj, PJ_PROJ_5, NULL);

        fprintf(fptf, "%s,\"%s\",\"%s\",\"%s\"\n", proj_crs_info[i]->code,
  	    proj_crs_info[i]->name, proj_definition, 
            proj_crs_info[i]->projection_method_name);
    }

    fclose(fptf);
    proj_destroy(pj);
    proj_crs_info_list_destroy(proj_crs_info);
    proj_context_destroy(ctx);
    INTEGER_POINTER(ans)[0] = crs_cnt;
    UNPROTECT(1);

    return(ans);

}

#ifdef __cplusplus
}
#endif
#endif


