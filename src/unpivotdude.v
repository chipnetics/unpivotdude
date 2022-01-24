// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import flag

fn main()
{
	mut fp := flag.new_flag_parser(os.args)
    fp.application('unpivotdude')
    fp.version('v0.0.1\nCopyright (c) 2022 jeffrey -at- ieee.org. All rights \
	reserved.\nUse of this source code (/program) is governed by an MIT \
	license,\nthat can be found in the LICENSE file.')
    fp.description('\nUnpivot input data on specific column combination.\n\
	Note that columns are 0-index based.')
    fp.skip_executable()
    pivot_column_arg := fp.string('pivot', `p`, "", 
								'Comma-separated list of pivot indexes.')
	header_column_arg := fp.string('header', `h`, "", 
								'Comma-separated list of header indexes.')
	mut has_header := fp.bool('no-header', `n`, false, 
								'Indicate input file has no header.')
	file_in := fp.string('file-in', `f`, "", 
								'Input file to pivot.')

	has_header = !has_header // flip the has_header argument (readibility)


	additional_args := fp.finalize() or {
        eprintln(err)
        println(fp.usage())
        return
    }

	if pivot_column_arg.len==0 || header_column_arg.len==0 ||
		file_in.len==0
	{
        println(fp.usage())
        return
	}

    additional_args.join_lines()

	pivot_column := expand_int_string(pivot_column_arg) // "0,4-6" --> [0,4,5,6]
	header_column := expand_int_string(header_column_arg)

	lines := os.read_lines(file_in) or {panic(err)}

	mut data_array := []Data{}
	mut data_struct := Data{}

	mut delimited_header := []string{}

	for index,line in lines
	{
		if index==0 && has_header
		{
			delimited_header = line.split("\t")
			continue
		}

		delimited_row := line.split("\t")
		mut pivot_col_string := ""

		for cols in pivot_column
		{
			pivot_col_string += delimited_row[cols.int()] + "\t"
		}

		for heads in header_column
		{
			data_struct.pivot_col = pivot_col_string.all_before_last("\t")
			data_struct.value = delimited_row[heads.int()]

			if has_header
			{
				data_struct.header_elem = delimited_header[heads.int()]
			}
			else
			{
				data_struct.header_elem = heads
			}
			data_array << data_struct	
		}
	}

	// Print out the header
	if !has_header // Source data does not have header; make one...
	{
		for value in pivot_column
		{
			print("col_$value\t")
		}
	}
	else // has header
	{
		for cols in pivot_column
		{
			print("${delimited_header[cols.int()]}\t")
		}
	}
	println("unpivot_col\tunpivot_val")
	// End of header creation...

	for data_pt in data_array
	{
		println("${data_pt.pivot_col}\t${data_pt.header_elem}\t${data_pt.value}")

	}
}

// "1,2,5-10,8"  ==> ['1', '2', '5', '6', '7', '8', '9', '10', '8']
fn expand_int_string(ranges string) []string
{
	ranges_split := ranges.split(",")
	mut return_arr := []string{}

	for elem in ranges_split
	{
		if elem.contains("-")
		{
			elem_split := elem.split("-")

			mut lower_bound:= elem_split[0].int()
			upper_bound:= elem_split[1].int()

			for i:=lower_bound; i<=upper_bound; i++
			{
				return_arr << i.str()
			}
		}
		else
		{
			return_arr << elem
		}
	}

	return return_arr
}
	
struct Data
{
	mut:
		header_elem string
		pivot_col string
		value string
}