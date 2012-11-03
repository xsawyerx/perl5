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
    PPCODE:
    XSRETURN_UV(PERL_HASH_SEED);

void
hash_function_name()
    PROTOTYPE:
    PPCODE:
    XSRETURN_PV(PERL_HASH_FUNC);

void
hash_value(string)
	SV* string
    PROTOTYPE: $
    PPCODE:
    STRLEN len;
    char *pv;
    UV uv;

    pv= SvPV(string,len);
    PERL_HASH(uv,pv,len);
    XSRETURN_UV(uv);


void
bucket_info(rhv)
        SV* rhv
    PPCODE:
{
    /*

    Takes a non-magical hash ref as an argument and returns a list of
    statistics about the hash. The number and keys and the size of the
    array will always be reported as the first two values. If the array is
    actually allocated (they are lazily allocated), then additionally
    will return a list of counts of bucket lengths. In other words in

        ($keys, $buckets, $used, @length_count)= hash::bucket_info(\%hash);

    $length_count[0] is the number of empty buckets, and $length_count[1]
    is the number of buckets with only one key in it, $buckets - $length_count[0]
    gives the number of used buckets, and @length_count-1 is the maximum
    bucket depth.

    If the argument is not a hash ref, or if it is magical, then returns
    nothing (the empty list).

    */
    if (SvROK(rhv) && SvTYPE(SvRV(rhv))==SVt_PVHV && !SvMAGICAL(SvRV(rhv))) {
        const HV * const hv = (const HV *) SvRV(rhv);
        U32 max_bucket_index= HvMAX(hv);
        U32 total_keys= HvUSEDKEYS(hv);
        HE **bucket_array= HvARRAY(hv);
        mXPUSHi(total_keys);
        mXPUSHi(max_bucket_index+1);
        mXPUSHi(0); /* for the number of used buckets */
#define BUCKET_INFO_ITEMS_ON_STACK 3
        if (!bucket_array) {
            XSRETURN(BUCKET_INFO_ITEMS_ON_STACK);
        } else {
            /* we use chain_length to index the stack - we eliminate an add
             * by initializing things with the number of items already on the stack.
             * If we have 2 items then ST(2+0) (the third stack item) will be the counter
             * for empty chains, ST(2+1) will be for chains with one element,  etc.
             */
            I32 max_chain_length= BUCKET_INFO_ITEMS_ON_STACK - 1; /* so we do not have to do an extra push for the 0 index */
            HE *he;
            U32 bucket_index;
            for ( bucket_index= 0; bucket_index <= max_bucket_index; bucket_index++ ) {
                I32 chain_length= BUCKET_INFO_ITEMS_ON_STACK;
                for (he= bucket_array[bucket_index]; he; he= HeNEXT(he) ) {
                    chain_length++;
                }
                while ( max_chain_length < chain_length ) {
                    mXPUSHi(0);
                    max_chain_length++;
                }
                SvIVX( ST( chain_length ) )++;
            }
            /* now set the number of used buckets */
            SvIVX( ST( BUCKET_INFO_ITEMS_ON_STACK - 1 ) ) = max_bucket_index - SvIVX( ST( BUCKET_INFO_ITEMS_ON_STACK ) ) + 1;
            XSRETURN( max_chain_length + 1 ); /* max_chain_length is the index of the last item on the stack, so we add 1 */
        }
#undef BUCKET_INFO_ITEMS_ON_STACK
    }
    XSRETURN(0);
}

