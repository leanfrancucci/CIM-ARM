
/*
 * Computer Algebra Kit (c) 1992,00 by Comp.Alg.Objects.  All Rights Reserved.
 * $Id: integer.h,v 1.1 2007-05-08 15:33:39 yerfino Exp $
 */

/*
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published 
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __CAINTEGER_HEADER__
#define __CAINTEGER_HEADER__

#include <Object.h>

#define INTEGER id
#define Integer BigInt

@interface BigInt : Object
{
  int myIntValue;
}

+ new;
+ int:(int)intValue;
- (BOOL) isEqual:b;
- (BOOL) notEqual:b;
- (int) intValue;
- (unsigned) hash;

@end

#endif /* __CAINTEGER_HEADER__ */
 
