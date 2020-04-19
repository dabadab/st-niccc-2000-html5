#!/bin/bash

function DEBUG() {
	echo -n "$1 " 1>&2
	shift
	for z in $@; do
		printf '%x ' $z 1>&2
	done
	echo 1>&2
}

function printJSON() {
	TMP=/tmp/xx.$$
	hexdump -v -e '/1 "%u\n"' scene1.bin >$TMP
	readarray -t D <$TMP
	rm $TMP

	x=0
	PALETTE=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
	frame_comma=''

	echo "var movie={"
	echo '  "frames": ['

	STOP=0

	FRAME=0;

	while [ $STOP -eq 0 ] ; do
		if [ $(($FRAME % 100 )) -eq 0 ] ; then
			DEBUG $FRAME
		fi

		echo "    $frame_comma{"
		if [ "$frame_comma" != ',' ]; then frame_comma=','; fi

		flags=${D[$x]}
		let x++
		#DEBUG flags $x $flags

		echo '      "frameIdx": '$FRAME','

		#
		##############  clear screen?  ###############################
		#
		echo -n '      "clr": '
		if [ $(($flags & 1)) -ne 0 ]; then echo -n true; else echo -n false; fi
		echo ','

		#
		##############  palette  #####################################
		#
		if [ $(($flags & 2)) -ne 0 ]; then
			# a palette update
			bitmask=$((${D[$x]} << 8 | ${D[$(($x + 1))]}))
			x=$(($x + 2))
			#DEBUG bitmask $x $bitmask

			colidx=0
			bit=$((1 << 15))
			while [ $colidx -le 15 ]; do
				if [ $(($bitmask & $bit)) -ne 0 ]; then
					rawcol=$((${D[$x]} << 8 | ${D[$(($x + 1))]}))
					x=$(($x + 2))
					#DEBUG rawcol $x $rawcol
					PALETTE[$colidx]=$((($rawcol & 7) << 5 | ($rawcol & 16#70) << 9 | ($rawcol & 16#700) << 13))
					#DEBUG color $colidx ${PALETTE[$colidx]}
				fi
				let colidx++
				bit=$(($bit >> 1))
			done
		fi

		# print palette (yeah, for every frame)
		echo '      "palette": ['
		comma=' '
		for col in ${PALETTE[@]}; do
			printf "        $comma\"#%06x\"\n" $col
			if [ "$comma" != ',' ]; then comma=','; fi
		done
		echo '      ],'

		#
		##############  polygons + vertices  #########################
		#


		# vertex list if in indexed mode

		if [ $(($flags & 4)) -ne 0 ]; then
			# indexed mode - vertex list
			vertex_count=${D[$x]}
			let x++
			vertex=0
			comma=' '
			echo '      "vertices": ['
			while [ $vertex -lt $vertex_count ]; do
				vertex_x=${D[$x]}
				let x++
				vertex_y=${D[$x]}
				let x++
				echo "        $comma{ \"x\": $vertex_x, \"y\": $vertex_y }"
				let vertex++
				if [ "$comma" != ',' ]; then comma=','; fi
			done
			echo '      ],'
		fi


		# polygons

		if [ $(($flags & 4)) -ne 0 ]; then
			vertex_name="verticesIdx"
		else
			vertex_name="vertices"
		fi
		echo '      "polygons": ['
		comma=' '
		while true; do
			polydesc=${D[$x]}
			let x++
			if [ $polydesc -ge 253 ]; then
				# end of frame
				if [ $polydesc -eq 254 ]; then
					# end of frame and skip to next 64k block
					let x+=65535
					x=$(($x & 16#ffff0000))

				elif [ $polydesc -eq 253 ]; then
					# end of movie
					STOP=1
				fi
				break

			fi
			vcount=$(($polydesc & 16#0f))
			vcolidx=$((($polydesc & 16#f0) >> 4))

			echo -n "        $comma{ \"colidx\": $vcolidx, \"$vertex_name\": ["
			if [ "$comma" != ',' ]; then comma=','; fi

			c=0
			inner_comma=''
			while [ $c -lt $vcount ]; do
				if [ $(($flags & 4)) -ne 0 ]; then
					vidx=${D[$x]}
					let x++
					echo -n "$inner_comma {\"idx\": $vidx}"
				else
					v_x=${D[$x]}
					let x++
					v_y=${D[$x]}
					let x++
					echo -n "$inner_comma {\"x\": $v_x, \"y\": $v_y}"
				fi
				if [ "$inner_comma" != ',' ]; then inner_comma=','; fi
				let c++
			done

			echo " ]}"
		done
		echo '      ],'

		echo '    }'

		let FRAME++
	done

	echo '  ]'
	echo "};"
}

printJSON >scene.js
