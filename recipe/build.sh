#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Findlib's Makefile needs bash 5.2+; the system bash may be older.
if [[ ${BASH_VERSINFO[0]} -lt 5 || (${BASH_VERSINFO[0]} -eq 5 && ${BASH_VERSINFO[1]} -lt 2) ]]; then
  echo "re-exec with conda bash..."
  if [[ -x "${BUILD_PREFIX}/bin/bash" ]]; then
    exec "${BUILD_PREFIX}/bin/bash" "$0" "$@"
  else
    echo "ERROR: Could not find conda bash at ${BUILD_PREFIX}/bin/bash"
    exit 1
  fi
fi

source "${RECIPE_DIR}/building/build_functions.sh"

LIBDIR="${PREFIX}"

./configure \
  -bindir "${LIBDIR}"/bin \
  -sitelib "${LIBDIR}"/lib/ocaml/site-lib \
  -config "${LIBDIR}"/etc/findlib.conf \
  -mandir "${LIBDIR}"/share/man || { cat ocargs.log; exit 1; }

# Resolve the stdlib path at runtime rather than baking in the build prefix, so
# both bytecode (.cma) and native (.cmxa) builds stay relocatable.
sed -i 's#let ocaml_stdlib = "@STDLIB@";;#let ocaml_stdlib = match Sys.getenv_opt "OCAMLLIB" with Some v -> v | None -> failwith "OCAMLLIB environment variable not set";;#g' src/findlib/findlib_config.mlp

make all
make opt
make install

# topfind is installed under BUILD_PREFIX; move it next to the other artifacts.
if [[ -f "${BUILD_PREFIX}/lib/ocaml/topfind" ]]; then
  mv "${BUILD_PREFIX}/lib/ocaml/topfind" "${LIBDIR}/lib/ocaml/"
fi

sed -i "s@${BUILD_PREFIX}@${PREFIX}@g" "${LIBDIR}"/etc/findlib.conf "${LIBDIR}"/lib/ocaml/site-lib/findlib/Makefile.config

for CHANGE in "activate" "deactivate"
do
  mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
  cp "${RECIPE_DIR}/scripts/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done
