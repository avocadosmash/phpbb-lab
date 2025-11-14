<?php
/**
 *
 * This file is part of the phpBB Forum Software package.
 *
 * @copyright (c) phpBB Limited <https://www.phpbb.com>
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 * For full copyright and license information, please see
 * the docs/CREDITS.txt file.
 *
 */

require_once __DIR__ . '/../../phpBB/includes/diff/diff.php';

class phpbb_diff3_test extends phpbb_test_case
{
	/**
	 * Test that diff3_op properties are accessible from outside the class
	 * This test addresses PHPBB-17560: Diff engine causes PHP fatal error
	 */
	public function test_diff3_op_properties_accessible()
	{
		$orig = array('line1', 'line2');
		$final1 = array('line1 modified', 'line2');
		$final2 = array('line1', 'line2 modified');

		$diff3_op = new diff3_op($orig, $final1, $final2);

		// These properties must be accessible from outside the class
		// If they are protected, this will cause a fatal error
		$this->assertEquals($orig, $diff3_op->orig);
		$this->assertEquals($final1, $diff3_op->final1);
		$this->assertEquals($final2, $diff3_op->final2);
	}

	/**
	 * Test that diff3 get_conflicts_content() works correctly
	 * This test verifies the fix for the specific issue reported
	 */
	public function test_diff3_get_conflicts_content()
	{
		$orig = array('original line 1', 'original line 2');
		$final1 = array('modified line 1 version 1', 'original line 2');
		$final2 = array('modified line 1 version 2', 'original line 2');

		$diff3 = new diff3($orig, $final1, $final2);

		// This should not throw a fatal error about accessing protected properties
		$conflicts_content = $diff3->get_conflicts_content();

		// Verify we got an array back
		$this->assertIsArray($conflicts_content);
	}

	/**
	 * Test that diff3 get_conflicts() works correctly
	 */
	public function test_diff3_get_conflicts()
	{
		$orig = array('original line 1', 'original line 2');
		$final1 = array('modified line 1 version 1', 'original line 2');
		$final2 = array('modified line 1 version 2', 'original line 2');

		$diff3 = new diff3($orig, $final1, $final2);

		// This should not throw a fatal error about accessing protected properties
		$conflicts = $diff3->get_conflicts();

		// Verify we got an array back
		$this->assertIsArray($conflicts);
	}

	/**
	 * Test that diff3 merged_new_output() works correctly
	 */
	public function test_diff3_merged_new_output()
	{
		$orig = array('original line 1', 'original line 2');
		$final1 = array('modified line 1 version 1', 'original line 2');
		$final2 = array('modified line 1 version 2', 'original line 2');

		$diff3 = new diff3($orig, $final1, $final2);

		// This should not throw a fatal error about accessing protected properties
		$merged = $diff3->merged_new_output();

		// Verify we got an array back
		$this->assertIsArray($merged);
	}

	/**
	 * Test that diff3 merged_orig_output() works correctly
	 */
	public function test_diff3_merged_orig_output()
	{
		$orig = array('original line 1', 'original line 2');
		$final1 = array('modified line 1 version 1', 'original line 2');
		$final2 = array('modified line 1 version 2', 'original line 2');

		$diff3 = new diff3($orig, $final1, $final2);

		// This should not throw a fatal error about accessing protected properties
		$merged = $diff3->merged_orig_output();

		// Verify we got an array back
		$this->assertIsArray($merged);
	}
}
