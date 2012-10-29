#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Hash::Util		PACKAGE = Hash::Util

void
all_keys(hash,keys,placeholder)
	HV *hash
	AV *keys
	AV *placeholder
    PROTOTYPE: \%\@\@
    PREINIT:
        SV *key;
        HE *he;
    PPCODE:
        av_clear(keys);
        av_clear(placeholder);

        (void)hv_iterinit(hash);
	while((he = hv_iternext_flags(hash, HV_ITERNEXT_WANTPLACEHOLDERS))!= NULL) {
	    key=hv_iterkeysv(he);
	    av_push(HeVAL(he) == &PL_sv_placeholder ? placeholder : keys,
		    SvREFCNT_inc(key));
        }
	XSRETURN(1);

void
hidden_ref_keys(hash)
	HV *hash
    ALIAS:
	Hash::Util::legal_ref_keys = 1
    PREINIT:
        SV *key;
        HE *he;
    PPCODE:
        (void)hv_iterinit(hash);
	while((he = hv_iternext_flags(hash, HV_ITERNEXT_WANTPLACEHOLDERS))!= NULL) {
	    key=hv_iterkeysv(he);
            if (ix || HeVAL(he) == &PL_sv_placeholder) {
                XPUSHs( key );
            }
        }

void
hv_store(hash, key, val)
	HV *hash
	SV* key
	SV* val
    PROTOTYPE: \%$$
    CODE:
    {
        SvREFCNT_inc(val);
	if (!hv_store_ent(hash, key, val, 0)) {
	    SvREFCNT_dec(val);
	    XSRETURN_NO;
	} else {
	    XSRETURN_YES;
	}
    }



void
hash_seed()
    PROTOTYPE:
    CODE:
    assert(PERL_HASH_SEED_SET == TRUE);
    XSRETURN_UV((PERL_HASH_SEED) & 0xFFFFFFFF);

void
hash_function_name()
    PROTOTYPE:
    CODE:
    XSRETURN_PV(PERL_HASH_FUNC);

void
hash_value(string)
	SV* string
    PROTOTYPE: $
    CODE:
    STRLEN len;
    char *pv;
    UV uv;

    pv= SvPV(string,len);
    PERL_HASH(uv,pv,len);
    XSRETURN_UV(uv);
