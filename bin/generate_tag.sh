#!/bin/bash

x=0.5
y=0.5
w=0.7
multipages=false

while [ -n "$1" ]; do
    token="$1"
    if [[ "${token:0:1}" = "-" ]]; then
	opt=${token}
	if [[ "${opt}" = "-h" || "${opt}" = "--help" ]]; then
            echo "WARNING: Sorry no help!"
            exit 0
	elif [[ "${opt}" = "-x" ]]; then
            shift 1
            x=$1
	elif [[ "${opt}" = "-y" ]]; then
            shift 1
            y=$1
	elif [[ "${opt}" = "-w" ]]; then
            shift 1
            w=$1
        elif [[ "${opt}" = "--multi" ]]; then
            multipages=true
        elif [[ "${opt}" = "--tag" ]]; then
            shift 1
            tag_file=$1
        else
            echo "ERROR: Unkown option '${opt}'"
            exit 1
        fi
    else
        pdfs+="$1 "
    fi
    shift 1
done

if [ -z "${pdfs}" ]; then
    echo "ERROR: Missing pdf file(s)!"
    exit 1
fi

if [ -z "${tag_file}" ]; then
    echo "ERROR: Missing tag file!"
    exit 1
fi

function generate_tmpl()
{
    cat << EOF > template.tex
\documentclass[crop]{standalone}
\usepackage{onimage}

\begin{document}
\begin{tikzonimage}{$1}
  \node[
    font=\large,
    minimum height=30mm,
    align=center,
    anchor=south, at={($x,1-$y)}] {
    \includegraphics[width=$w\linewidth]{$2}
  };
\end{tikzonimage}
\end{document}
EOF
}

temp_dir=/tmp/pdf.d
mkdir -p ${temp_dir}

current_path=`(cd $(dirname $0) && pwd)`
mkdir -p ${current_path}/pdf

for pdf in "${pdfs:0:-1}"; do
    new_pdf=${pdf// /_}
    if [[ ${new_pdf} != ${pdf} ]]; then
        mv "$pdf" ${new_pdf}
    fi
    pdf=${new_pdf}

    cp ${tag_file} ${temp_dir}
    cp ${pdf} ${temp_dir}
    (
        cd ${temp_dir}
        if ${multipages}; then
            pdfseparate ${pdf} ./pdf_%05d.pdf

            for i in *.pdf; do
                generate_tmpl $i ${tag_file}
                pdflatex -halt-on-error template.tex
                mv template.pdf $i
            done
            pdfjam *.pdf
            mv ${temp_dir}/*-pdfjam.pdf ${current_path}/pdf/$(basename $pdf)
        else
            generate_tmpl $pdf ${tag_file}
            pdflatex -halt-on-error -output-dir=${temp_dir} template.tex
            cp ${temp_dir}/template.pdf ${current_path}/pdf/$(basename $pdf)
        fi
    )

    rm -rf ${temp_dir}

done
